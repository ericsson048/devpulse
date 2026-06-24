from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from datetime import datetime, timedelta, timezone
import secrets
import logging

from app.database import get_db
from app.models import User, UserRole
from app.schemas import LoginRequest, RegisterRequest, TokenResponse, ForgotPasswordRequest, ResetPasswordRequest
from app.auth import hash_password, verify_password, create_access_token, get_current_user
from app.config import get_settings
from app.limiter import limiter

router = APIRouter(prefix="/auth", tags=["Auth"])
settings = get_settings()
logger = logging.getLogger("devpulse")


@router.post("/register", response_model=TokenResponse)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.email == body.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        email=body.email,
        hashed_password=hash_password(body.password),
        display_name=body.display_name,
        role=UserRole.user,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token, user=user)


@router.post("/login", response_model=TokenResponse)
@limiter.limit("5/minute")
async def login(request: Request, body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token, user=user)


@router.post("/forgot-password")
async def forgot_password(body: ForgotPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()
    if not user:
        return {"message": "If that email exists, a reset link has been sent"}
    user.reset_token = secrets.token_urlsafe(32)
    user.reset_token_expires = datetime.now(timezone.utc) + timedelta(hours=1)
    await db.commit()
    from app.email_utils import send_reset_email
    await send_reset_email(user.email, user.reset_token)
    return {"message": "If that email exists, a reset link has been sent"}


@router.post("/verify-reset-token")
async def verify_reset_token(body: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(
            User.reset_token == body.token,
            User.reset_token_expires > datetime.now(timezone.utc),
        )
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token")
    return {"valid": True}


@router.post("/reset-password")
async def reset_password(body: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(User).where(
            User.reset_token == body.token,
            User.reset_token_expires > datetime.now(timezone.utc),
        )
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=400, detail="Invalid or expired reset token")
    user.hashed_password = hash_password(body.new_password)
    user.reset_token = None
    user.reset_token_expires = None
    await db.commit()
    return {"message": "Password reset successfully"}


@router.get("/me", response_model=TokenResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    token = create_access_token({"sub": str(current_user.id)})
    return TokenResponse(access_token=token, user=current_user)


@router.post("/backoffice-login", response_model=TokenResponse)
async def backoffice_login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    """Login for backoffice admin — checks against env credentials first."""
    if body.email == settings.BACKOFFICE_USERNAME and body.password == settings.BACKOFFICE_PASSWORD:
        # Find or create admin user
        result = await db.execute(select(User).where(User.role == UserRole.admin))
        admin = result.scalar_one_or_none()
        if not admin:
            admin = User(
                email="admin@devpulse.io",
                hashed_password=hash_password(settings.BACKOFFICE_PASSWORD),
                display_name="Admin",
                role=UserRole.admin,
            )
            db.add(admin)
            await db.commit()
            await db.refresh(admin)
        token = create_access_token({"sub": str(admin.id)})
        return TokenResponse(access_token=token, user=admin)

    # Fallback to normal user login
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Admin access required")

    token = create_access_token({"sub": str(user.id)})
    return TokenResponse(access_token=token, user=user)
