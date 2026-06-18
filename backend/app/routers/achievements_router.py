from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Achievement, User
from app.schemas import AchievementOut
from app.auth import get_admin_user

router = APIRouter(prefix="/achievements", tags=["Achievements"])


@router.get("/", response_model=list[AchievementOut])
async def list_achievements(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Achievement).order_by(Achievement.title))
    return result.scalars().all()


@router.get("/{achievement_id}", response_model=AchievementOut)
async def get_achievement(achievement_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Achievement).where(Achievement.id == achievement_id))
    ach = result.scalar_one_or_none()
    if not ach:
        raise HTTPException(status_code=404, detail="Achievement not found")
    return ach


@router.post("/", response_model=AchievementOut)
async def create_achievement(
    body: AchievementOut,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    ach = Achievement(**body.model_dump())
    db.add(ach)
    await db.commit()
    await db.refresh(ach)
    return ach


@router.patch("/{achievement_id}", response_model=AchievementOut)
async def update_achievement(
    achievement_id: int,
    body: AchievementOut,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Achievement).where(Achievement.id == achievement_id))
    ach = result.scalar_one_or_none()
    if not ach:
        raise HTTPException(status_code=404, detail="Achievement not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(ach, k, v)
    await db.commit()
    await db.refresh(ach)
    return ach


@router.delete("/{achievement_id}")
async def delete_achievement(
    achievement_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Achievement).where(Achievement.id == achievement_id))
    ach = result.scalar_one_or_none()
    if not ach:
        raise HTTPException(status_code=404, detail="Achievement not found")
    await db.delete(ach)
    await db.commit()
    return {"ok": True}
