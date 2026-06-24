from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, case
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import User, UserProgress, Course, Module, Quiz, QuizAttempt, Achievement
from app.schemas import (
    ProgressUpdateRequest, UserProgressOut, BackofficeDashboard,
    AdminDashboardCharts, WeeklyDataPoint, CourseProgressStat,
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


# ── Backoffice dashboard charts ───────────────────────────────────
def _grade_for_ratio(ratio: float) -> str:
    if ratio >= 0.95:
        return "S"
    if ratio >= 0.85:
        return "A"
    if ratio >= 0.70:
        return "B"
    if ratio >= 0.50:
        return "C"
    return "F"


@router.get("/admin/dashboard/charts", response_model=AdminDashboardCharts)
async def admin_dashboard_charts(
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    now = datetime.now(timezone.utc)
    twelve_weeks_ago = now - timedelta(weeks=12)

    # Weekly registrations
    reg_rows = await db.execute(
        select(
            func.date_trunc("week", User.created_at).label("week"),
            func.count().label("count"),
        ).where(User.created_at >= twelve_weeks_ago)
        .group_by("week")
        .order_by("week")
    )
    weekly_regs = {}
    for row in reg_rows:
        weekly_regs[row.week.strftime("%Y-%m-%d")] = row.count

    # Weekly quiz attempts
    qa_rows = await db.execute(
        select(
            func.date_trunc("week", QuizAttempt.created_at).label("week"),
            func.count().label("count"),
        ).where(QuizAttempt.created_at >= twelve_weeks_ago)
        .group_by("week")
        .order_by("week")
    )
    weekly_qa = {}
    for row in qa_rows:
        weekly_qa[row.week.strftime("%Y-%m-%d")] = row.count

    # Fill missing weeks
    weekly_registrations = []
    weekly_quiz_attempts = []
    cursor = twelve_weeks_ago
    while cursor <= now:
        wk = cursor.strftime("%Y-%m-%d")
        weekly_registrations.append(WeeklyDataPoint(week=wk, count=weekly_regs.get(wk, 0)))
        weekly_quiz_attempts.append(WeeklyDataPoint(week=wk, count=weekly_qa.get(wk, 0)))
        cursor += timedelta(weeks=1)

    # Quiz grades — compute from all attempts
    all_attempts = await db.execute(
        select(QuizAttempt.score, QuizAttempt.total_questions)
    )
    grades: dict[str, int] = {"S": 0, "A": 0, "B": 0, "C": 0, "F": 0}
    for row in all_attempts:
        ratio = row.score / row.total_questions if row.total_questions > 0 else 0
        grade = _grade_for_ratio(ratio)
        grades[grade] = grades.get(grade, 0) + 1

    # Level distribution
    level_rows = await db.execute(
        select(User.level, func.count().label("count"))
        .group_by(User.level)
        .order_by(User.level)
    )
    level_distribution = [{"level": r.level, "count": r.count} for r in level_rows]

    # Course progress
    progress_rows = await db.execute(
        select(
            Course.title,
            UserProgress.status,
            func.count().label("count"),
        )
        .join(Course, UserProgress.course_id == Course.id)
        .group_by(Course.title, UserProgress.status)
        .order_by(Course.title)
    )
    course_map: dict[str, dict[str, int]] = {}
    for row in progress_rows:
        if row.title not in course_map:
            course_map[row.title] = {"completed": 0, "in_progress": 0, "not_started": 0}
        if row.status in course_map[row.title]:
            course_map[row.title][row.status] = row.count

    course_progress = [
        CourseProgressStat(
            course=title,
            completed=stats["completed"],
            in_progress=stats["in_progress"],
            not_started=stats["not_started"],
        )
        for title, stats in course_map.items()
    ]

    return AdminDashboardCharts(
        weekly_registrations=weekly_registrations,
        weekly_quiz_attempts=weekly_quiz_attempts,
        quiz_grades=grades,
        level_distribution=level_distribution,
        course_progress=course_progress,
    )
