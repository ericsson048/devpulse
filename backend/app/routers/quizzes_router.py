import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models import Quiz, QuizQuestion, QuizAttempt, User, UserProgress
from app.schemas import (
    QuizCreate, QuizOut, QuizPlayerOut, QuizQuestionOut,
    QuizSubmitRequest, QuizSubmitResult,
)
from app.auth import get_current_user, get_admin_user

router = APIRouter(prefix="/quizzes", tags=["Quizzes"])


# ── Player endpoints ──────────────────────────────────────────────
@router.get("/{quiz_id}", response_model=QuizPlayerOut)
async def get_quiz_for_player(
    quiz_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Quiz).where(Quiz.id == quiz_id))
    quiz = result.scalar_one_or_none()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    q_result = await db.execute(
        select(QuizQuestion)
        .where(QuizQuestion.quiz_id == quiz_id)
        .order_by(QuizQuestion.sort_order)
    )
    questions = q_result.scalars().all()

    return QuizPlayerOut(
        id=quiz.id,
        module_id=quiz.module_id,
        title=quiz.title,
        time_limit_seconds=quiz.time_limit_seconds,
        xp_reward=quiz.xp_reward,
        questions=[QuizQuestionPlayer.model_validate(q) for q in questions],
    )


@router.post("/{quiz_id}/submit", response_model=QuizSubmitResult)
async def submit_quiz(
    quiz_id: int,
    body: QuizSubmitRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Quiz).where(Quiz.id == quiz_id))
    quiz = result.scalar_one_or_none()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")

    q_result = await db.execute(
        select(QuizQuestion)
        .where(QuizQuestion.quiz_id == quiz_id)
        .order_by(QuizQuestion.sort_order)
    )
    questions = q_result.scalars().all()

    correct = 0
    total = len(questions)
    for ans in body.answers:
        q = next((q for q in questions if q.id == ans.question_id), None)
        if q and ans.selected == q.correct_answer:
            correct += 1

    pct = correct / total if total > 0 else 0
    passed = pct >= quiz.passing_score
    xp_earned = int(quiz.xp_reward * pct) if passed else int(quiz.xp_reward * pct * 0.5)

    # Grade
    if pct >= 0.9:
        grade = "S"
    elif pct >= 0.8:
        grade = "A"
    elif pct >= 0.7:
        grade = "B"
    elif pct >= 0.5:
        grade = "C"
    else:
        grade = "F"

    # Save attempt
    attempt = QuizAttempt(
        user_id=current_user.id,
        quiz_id=quiz_id,
        score=correct,
        total_questions=total,
        xp_earned=xp_earned,
        passed=passed,
        answers=json.dumps([a.model_dump() for a in body.answers]),
    )
    db.add(attempt)

    # Award XP
    current_user.xp += xp_earned

    await db.commit()

    return QuizSubmitResult(
        score=correct,
        total=total,
        xp_earned=xp_earned,
        passed=passed,
        grade=grade,
    )


# ── Admin CRUD ────────────────────────────────────────────────────
@router.post("/", response_model=QuizOut)
async def create_quiz(
    body: QuizCreate,
    module_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    quiz = Quiz(module_id=module_id, title=body.title,
                time_limit_seconds=body.time_limit_seconds,
                passing_score=body.passing_score,
                xp_reward=body.xp_reward,
                is_published=body.is_published)
    db.add(quiz)
    await db.flush()

    for i, q in enumerate(body.questions):
        question = QuizQuestion(
            quiz_id=quiz.id,
            question_text=q.question_text,
            code_snippet=q.code_snippet,
            option_a=q.option_a, option_b=q.option_b,
            option_c=q.option_c, option_d=q.option_d,
            correct_answer=q.correct_answer,
            explanation=q.explanation,
            sort_order=q.sort_order or i,
        )
        db.add(question)

    await db.commit()
    await db.refresh(quiz)
    return quiz


@router.get("/admin/{quiz_id}", response_model=QuizOut)
async def get_quiz_admin(
    quiz_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Quiz).where(Quiz.id == quiz_id))
    quiz = result.scalar_one_or_none()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    q_result = await db.execute(
        select(QuizQuestion).where(QuizQuestion.quiz_id == quiz_id).order_by(QuizQuestion.sort_order)
    )
    quiz.questions = q_result.scalars().all()
    return quiz


@router.delete("/{quiz_id}")
async def delete_quiz(
    quiz_id: int,
    admin: User = Depends(get_admin_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Quiz).where(Quiz.id == quiz_id))
    quiz = result.scalar_one_or_none()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    await db.delete(quiz)
    await db.commit()
    return {"ok": True}
