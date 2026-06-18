from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete

from app.database import get_db
from app.models import Course, CourseLevel, Module, UserProgress, User
from app.schemas import CourseCreate, CourseUpdate, CourseOut, CourseWithProgress, ModuleOut, PaginatedResponse
from app.auth import get_current_user, get_admin_user

router = APIRouter(prefix="/courses", tags=["Courses"])


def _course_with_progress(course: Course, progress_percent: float = 0.0,
                           user_status: str = "not_started", modules_completed: int = 0) -> CourseWithProgress:
    return CourseWithProgress(
        **{k: getattr(course, k) for k in course.__table__.columns.keys()},
        progress_percent=progress_percent,
        user_status=user_status,
        modules_completed=modules_completed,
    )


# ── Public endpoints ──────────────────────────────────────────────
@router.get("/", response_model=list[CourseOut])
async def list_courses(
    level: str = None,
    language: str = None,
    published_only: bool = True,
    skip: int = 0,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
):
    q = select(Course)
    if published_only:
        q = q.where(Course.is_published == True)
    if level:
        q = q.where(Course.level == level)
    if language:
        q = q.where(Course.language == language)
    q = q.order_by(Course.sort_order).offset(skip).limit(limit)
    result = await db.execute(q)
    return result.scalars().all()


@router.get("/library", response_model=PaginatedResponse[CourseWithProgress])
async def library_courses(
    level: str = None,
    language: str = None,
    search: str = None,
    skip: int = 0,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    q = select(Course).where(Course.is_published == True)
    if level:
        q = q.where(Course.level == level)
    if language:
        q = q.where(Course.language == language)
    if search:
        q = q.where(Course.title.ilike(f"%{search}%"))
    q = q.order_by(Course.sort_order)

    total_q = await db.execute(select(func.count()).select_from(q.subquery()))
    total = total_q.scalar() or 0

    q = q.offset(skip).limit(limit)
    result = await db.execute(q)
    courses = result.scalars().all()

    # Get user progress for these courses
    progress_q = await db.execute(
        select(UserProgress).where(UserProgress.user_id == current_user.id)
    )
    progresses = progress_q.scalars().all()
    progress_map = {}
    for p in progresses:
        if p.course_id not in progress_map or p.progress_percent > progress_map[p.course_id].progress_percent:
            progress_map[p.course_id] = p

    out = []
    for c in courses:
        p = progress_map.get(c.id)
        out.append(_course_with_progress(
            c,
            progress_percent=p.progress_percent if p else 0.0,
            user_status=p.status if p else "not_started",
            modules_completed=0,
        ))
    return PaginatedResponse(items=out, total=total, skip=skip, limit=limit)


@router.get("/{course_id}", response_model=CourseOut)
async def get_course(course_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course


@router.post("/{course_id}/enroll", response_model=CourseWithProgress)
async def enroll_course(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    existing = await db.execute(
        select(UserProgress).where(
            UserProgress.user_id == current_user.id,
            UserProgress.course_id == course_id,
            UserProgress.lesson_id.is_(None),
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Already enrolled")

    progress = UserProgress(
        user_id=current_user.id,
        course_id=course_id,
        status="in_progress",
        progress_percent=0.0,
    )
    db.add(progress)
    await db.commit()
    await db.refresh(progress)

    return _course_with_progress(course, user_status="in_progress")


@router.post("/{course_id}/unenroll")
async def unenroll_course(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    await db.execute(
        delete(UserProgress).where(
            UserProgress.user_id == current_user.id,
            UserProgress.course_id == course_id,
        )
    )
    await db.commit()
    return {"ok": True}


@router.get("/{course_id}/modules", response_model=list[ModuleOut])
async def get_course_modules(course_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Module)
        .where(Module.course_id == course_id)
        .order_by(Module.sort_order)
    )
    return result.scalars().all()


# ── Admin endpoints ───────────────────────────────────────────────
@router.post("/", response_model=CourseOut)
async def create_course(
    body: CourseCreate,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    course = Course(**body.model_dump())
    db.add(course)
    await db.commit()
    await db.refresh(course)
    return course


@router.patch("/{course_id}", response_model=CourseOut)
async def update_course(
    course_id: int,
    body: CourseUpdate,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(course, k, v)
    await db.commit()
    await db.refresh(course)
    return course


@router.delete("/{course_id}")
async def delete_course(
    course_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    await db.delete(course)
    await db.commit()
    return {"ok": True}
