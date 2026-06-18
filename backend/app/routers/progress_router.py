from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import User, UserProgress, Course, Module, Quiz, QuizAttempt, Achievement
from app.schemas import (
    ProgressUpdateRequest, UserProgressOut, BackofficeDashboard,
)
from app.auth import get_current_user, get_admin_user

router = APIRouter(prefix="/progress", tags=["Progress"])


@router.post("/lesson")
async def complete_lesson(
    body: ProgressUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Check if progress already exists
    result = await db.execute(
        select(UserProgress).where(
            UserProgress.user_id == current_user.id,
            UserProgress.lesson_id == body.lesson_id,
        )
    )
    existing = result.scalar_one_or_none()

    if existing:
        existing.status = body.status
        existing.progress_percent = 1.0 if body.status == "completed" else existing.progress_percent
    else:
        # Get the lesson's module/course
        from app.models import Lesson
        lesson_q = await db.execute(
            select(Lesson).options(selectinload(Lesson.module)).where(Lesson.id == body.lesson_id)
        )
        lesson = lesson_q.scalar_one_or_none()
        if not lesson:
            raise HTTPException(status_code=404, detail="Lesson not found")

        progress = UserProgress(
            user_id=current_user.id,
            course_id=lesson.module.course_id if lesson.module else 0,
            module_id=lesson.module_id,
            lesson_id=body.lesson_id,
            status=body.status,
            progress_percent=1.0 if body.status == "completed" else 0.5,
            xp_earned=lesson.xp_reward if body.status == "completed" else 0,
        )
        db.add(progress)

        if body.status == "completed":
            current_user.xp += lesson.xp_reward

    await db.commit()
    return {"ok": True, "xp_earned": lesson.xp_reward if body.status == "completed" else 0}


# ── Backoffice dashboard ──────────────────────────────────────────
@router.get("/admin/dashboard", response_model=BackofficeDashboard)
async def admin_dashboard(
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    total_users = await db.execute(select(func.count()).select_from(User))
    total_courses = await db.execute(select(func.count()).select_from(Course))
    total_modules = await db.execute(select(func.count()).select_from(Module))
    total_quizzes = await db.execute(select(func.count()).select_from(Quiz))
    total_attempts = await db.execute(select(func.count()).select_from(QuizAttempt))

    return BackofficeDashboard(
        total_users=total_users.scalar() or 0,
        total_courses=total_courses.scalar() or 0,
        total_modules=total_modules.scalar() or 0,
        total_quizzes=total_quizzes.scalar() or 0,
        active_users_today=0,
        total_quiz_attempts=total_attempts.scalar() or 0,
    )
