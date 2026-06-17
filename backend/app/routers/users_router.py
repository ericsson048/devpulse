from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models import User, UserProgress, QuizAttempt, Achievement, UserAchievement
from app.schemas import UserOut, UserUpdate, HomeDashboard, CourseWithProgress, AchievementOut
from app.auth import get_current_user, get_admin_user

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=UserOut)
async def get_my_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=UserOut)
async def update_my_profile(
    body: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if body.display_name is not None:
        current_user.display_name = body.display_name
    if body.avatar_url is not None:
        current_user.avatar_url = body.avatar_url
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.get("/me/dashboard", response_model=HomeDashboard)
async def get_home_dashboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # In-progress courses
    progress_rows = await db.execute(
        select(UserProgress)
        .where(UserProgress.user_id == current_user.id)
        .where(UserProgress.status != "not_started")
    )
    progresses = progress_rows.scalars().all()

    course_ids = list(set(p.course_id for p in progresses if p.course_id))
    from app.models import Course
    courses_q = await db.execute(select(Course).where(Course.id.in_(course_ids))) if course_ids else None
    courses = courses_q.scalars().all() if courses_q else []

    in_progress = []
    for c in courses:
        cp = [p for p in progresses if p.course_id == c.id]
        best = max((p.progress_percent for p in cp), default=0)
        best_status = "in_progress" if best < 1.0 else "completed"
        in_progress.append(CourseWithProgress(
            **{k: getattr(c, k) for k in c.__table__.columns.keys()},
            progress_percent=best,
            user_status=best_status,
            modules_completed=sum(1 for p in cp if p.status == "completed"),
        ))

    # Achievements count
    ach_count = await db.execute(
        select(func.count()).select_from(UserAchievement)
        .where(UserAchievement.user_id == current_user.id)
    )

    # Global rank
    rank_q = await db.execute(
        select(func.count()).select_from(User).where(User.xp > current_user.xp)
    )
    rank = (rank_q.scalar() or 0) + 1

    # Daily XP (simplified: use total XP, in prod would sum today's progress)
    daily_xp = min(current_user.xp, 750)

    return HomeDashboard(
        display_name=current_user.display_name,
        level=current_user.level,
        xp=current_user.xp,
        xp_next_level=current_user.level * 1000,
        streak=current_user.streak,
        daily_goal_xp=1000,
        daily_xp_earned=daily_xp,
        in_progress_courses=in_progress[:5],
        achievements_count=ach_count.scalar() or 0,
        global_rank=rank,
    )


@router.get("/me/achievements")
async def get_my_achievements(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserAchievement)
        .where(UserAchievement.user_id == current_user.id)
    )
    return result.scalars().all()


@router.get("/me/progress")
async def get_my_progress(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id)
    )
    return result.scalars().all()


# ── Admin endpoints ───────────────────────────────────────────────
@router.get("/", response_model=list[UserOut])
async def list_users(
    skip: int = 0,
    limit: int = 50,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).offset(skip).limit(limit))
    return result.scalars().all()


@router.get("/{user_id}", response_model=UserOut)
async def get_user(
    user_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
