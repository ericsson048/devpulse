from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Module, Lesson, Quiz, User
from app.schemas import ModuleCreate, ModuleUpdate, ModuleOut, LessonCreate, LessonUpdate, LessonOut
from app.auth import get_admin_user

router = APIRouter(prefix="/modules", tags=["Modules"])


@router.get("/{module_id}", response_model=ModuleOut)
async def get_module(module_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Module).where(Module.id == module_id))
    module = result.scalar_one_or_none()
    if not module:
        raise HTTPException(status_code=404, detail="Module not found")
    return module


@router.get("/{module_id}/lessons", response_model=list[LessonOut])
async def get_module_lessons(module_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Lesson).where(Lesson.module_id == module_id).order_by(Lesson.sort_order)
    )
    return result.scalars().all()


@router.get("/lessons/{lesson_id}", response_model=LessonOut)
async def get_lesson(lesson_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")

    out = LessonOut(
        id=lesson.id,
        module_id=lesson.module_id,
        title=lesson.title,
        lesson_type=lesson.lesson_type,
        content=lesson.content,
        video_url=lesson.video_url,
        resources=lesson.resources,
        code_template=lesson.code_template,
        code_language=lesson.code_language,
        has_editor=lesson.has_editor,
        sort_order=lesson.sort_order,
        xp_reward=lesson.xp_reward,
        is_published=lesson.is_published,
        created_at=lesson.created_at,
    )

    # If lesson is a quiz, fetch the associated quiz_id for the module
    if lesson.lesson_type == "quiz":
        quiz_result = await db.execute(
            select(Quiz).where(Quiz.module_id == lesson.module_id).limit(1)
        )
        quiz = quiz_result.scalar_one_or_none()
        if quiz:
            out.quiz_id = quiz.id

    return out


# ── Admin CRUD ────────────────────────────────────────────────────
@router.post("/", response_model=ModuleOut)
async def create_module(
    body: ModuleCreate,
    course_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    module = Module(course_id=course_id, **body.model_dump())
    db.add(module)
    # Update course module count
    from app.models import Course
    course_result = await db.execute(select(Course).where(Course.id == course_id))
    course = course_result.scalar_one_or_none()
    if course:
        course.total_modules = (course.total_modules or 0) + 1
    await db.commit()
    await db.refresh(module)
    return module


@router.patch("/{module_id}", response_model=ModuleOut)
async def update_module(
    module_id: int,
    body: ModuleUpdate,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Module).where(Module.id == module_id))
    module = result.scalar_one_or_none()
    if not module:
        raise HTTPException(status_code=404, detail="Module not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(module, k, v)
    await db.commit()
    await db.refresh(module)
    return module


@router.delete("/{module_id}")
async def delete_module(
    module_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Module).where(Module.id == module_id))
    module = result.scalar_one_or_none()
    if not module:
        raise HTTPException(status_code=404, detail="Module not found")
    await db.delete(module)
    await db.commit()
    return {"ok": True}


# ── Lesson Admin CRUD ─────────────────────────────────────────────
@router.post("/{module_id}/lessons", response_model=LessonOut)
async def create_lesson(
    module_id: int,
    body: LessonCreate,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    lesson = Lesson(module_id=module_id, **body.model_dump())
    db.add(lesson)
    # Update module lesson count
    result = await db.execute(select(Module).where(Module.id == module_id))
    module = result.scalar_one_or_none()
    if module:
        module.total_lessons = (module.total_lessons or 0) + 1
    await db.commit()
    await db.refresh(lesson)
    return lesson


@router.patch("/lessons/{lesson_id}", response_model=LessonOut)
async def update_lesson(
    lesson_id: int,
    body: LessonUpdate,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(lesson, k, v)
    await db.commit()
    await db.refresh(lesson)
    return lesson


@router.delete("/lessons/{lesson_id}")
async def delete_lesson(
    lesson_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Lesson).where(Lesson.id == lesson_id))
    lesson = result.scalar_one_or_none()
    if not lesson:
        raise HTTPException(status_code=404, detail="Lesson not found")
    await db.delete(lesson)
    await db.commit()
    return {"ok": True}
