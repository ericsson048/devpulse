from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List, TypeVar, Generic
from datetime import datetime

T = TypeVar("T")
from app.models.models import UserRole, CourseLevel, LessonType


# ── Auth ──────────────────────────────────────────────────────────
class LoginRequest(BaseModel):
    email: str
    password: str


class RegisterRequest(BaseModel):
    email: str
    password: str
    display_name: str = "Developer"


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserOut"


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


# ── User ──────────────────────────────────────────────────────────
class UserOut(BaseModel):
    id: int
    email: str
    display_name: str
    avatar_url: Optional[str] = None
    role: UserRole
    level: int
    xp: int
    streak: int
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None


class UserStats(BaseModel):
    total_users: int
    active_today: int
    total_xp_distributed: int
    average_level: float


# ── Course ────────────────────────────────────────────────────────
class CourseCreate(BaseModel):
    title: str
    description: Optional[str] = None
    icon: Optional[str] = None
    tag: Optional[str] = None
    level: CourseLevel = CourseLevel.beginner
    language: Optional[str] = None
    total_xp: int = 0
    sort_order: int = 0
    is_published: bool = False


class CourseUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    icon: Optional[str] = None
    tag: Optional[str] = None
    level: Optional[CourseLevel] = None
    language: Optional[str] = None
    total_xp: Optional[int] = None
    sort_order: Optional[int] = None
    is_published: Optional[bool] = None


class CourseOut(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    icon: Optional[str] = None
    tag: Optional[str] = None
    level: CourseLevel
    language: Optional[str] = None
    total_modules: int
    total_xp: int
    sort_order: int
    is_published: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class CourseWithProgress(CourseOut):
    progress_percent: float = 0.0
    user_status: str = "not_started"
    modules_completed: int = 0


# ── Module ────────────────────────────────────────────────────────
class ModuleCreate(BaseModel):
    title: str
    description: Optional[str] = None
    sort_order: int = 0
    total_xp: int = 0
    is_published: bool = False


class ModuleUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    sort_order: Optional[int] = None
    total_xp: Optional[int] = None
    is_published: Optional[bool] = None


class ModuleOut(BaseModel):
    id: int
    course_id: int
    title: str
    description: Optional[str] = None
    sort_order: int
    total_lessons: int
    total_xp: int
    is_published: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# ── Lesson ────────────────────────────────────────────────────────
class LessonCreate(BaseModel):
    title: str
    lesson_type: LessonType = LessonType.theory
    # Markdown body
    content: Optional[str] = None
    # Optional video URL
    video_url: Optional[str] = None
    # JSON string: [{"title": str, "url": str, "type": "pdf"|"link"|"github"}]
    resources: Optional[str] = None
    # Code editor
    code_template: Optional[str] = None
    code_solution: Optional[str] = None
    code_language: Optional[str] = None
    has_editor: bool = False
    sort_order: int = 0
    xp_reward: int = 25
    is_published: bool = False


class LessonUpdate(BaseModel):
    title: Optional[str] = None
    lesson_type: Optional[LessonType] = None
    content: Optional[str] = None
    video_url: Optional[str] = None
    resources: Optional[str] = None
    code_template: Optional[str] = None
    code_solution: Optional[str] = None
    code_language: Optional[str] = None
    has_editor: Optional[bool] = None
    sort_order: Optional[int] = None
    xp_reward: Optional[int] = None
    is_published: Optional[bool] = None


class LessonOut(BaseModel):
    id: int
    module_id: int
    title: str
    lesson_type: LessonType
    content: Optional[str] = None
    video_url: Optional[str] = None
    resources: Optional[str] = None
    code_template: Optional[str] = None
    code_language: Optional[str] = None
    has_editor: bool = False
    sort_order: int
    xp_reward: int
    is_published: bool
    created_at: datetime
    quiz_id: Optional[int] = None

    model_config = {"from_attributes": True}

    @field_validator("has_editor", mode="before")
    @classmethod
    def coerce_has_editor(cls, v: object) -> bool:
        return False if v is None else bool(v)


# ── Quiz ──────────────────────────────────────────────────────────
class QuizQuestionCreate(BaseModel):
    question_text: str
    code_snippet: Optional[str] = None
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_answer: int  # 0=A, 1=B, 2=C, 3=D
    explanation: Optional[str] = None
    sort_order: int = 0


class QuizQuestionOut(BaseModel):
    id: int
    question_text: str
    code_snippet: Optional[str] = None
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    correct_answer: int
    explanation: Optional[str] = None
    sort_order: int

    model_config = {"from_attributes": True}


class QuizQuestionPlayer(BaseModel):
    """For the player — hides correct_answer and explanation."""
    id: int
    question_text: str
    code_snippet: Optional[str] = None
    option_a: str
    option_b: str
    option_c: str
    option_d: str
    sort_order: int

    model_config = {"from_attributes": True}


class QuizCreate(BaseModel):
    title: str
    time_limit_seconds: int = 45
    passing_score: float = 0.7
    xp_reward: int = 250
    is_published: bool = False
    questions: List[QuizQuestionCreate] = []


class QuizOut(BaseModel):
    id: int
    module_id: int
    title: str
    time_limit_seconds: int
    passing_score: float
    xp_reward: int
    is_published: bool
    questions: List[QuizQuestionOut] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class QuizPlayerOut(BaseModel):
    id: int
    module_id: int
    title: str
    time_limit_seconds: int
    xp_reward: int
    questions: List[QuizQuestionPlayer] = []

    model_config = {"from_attributes": True}


class QuizSubmitAnswer(BaseModel):
    question_id: int
    selected: int  # 0=A, 1=B, 2=C, 3=D


class QuizSubmitRequest(BaseModel):
    answers: List[QuizSubmitAnswer]


class QuizSubmitResult(BaseModel):
    score: int
    total: int
    xp_earned: int
    passed: bool
    grade: str


# ── Progress ──────────────────────────────────────────────────────
class UserProgressOut(BaseModel):
    id: int
    course_id: int
    module_id: Optional[int] = None
    lesson_id: Optional[int] = None
    status: str
    progress_percent: float
    xp_earned: int
    completed_at: Optional[datetime] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class ProgressUpdateRequest(BaseModel):
    lesson_id: int
    status: str = "completed"


# ── Achievement ───────────────────────────────────────────────────
class AchievementOut(BaseModel):
    id: int
    title: str
    description: Optional[str] = None
    icon: Optional[str] = None
    icon_bg: Optional[str] = None
    icon_color: Optional[str] = None
    xp_reward: int
    condition_type: Optional[str] = None
    condition_value: Optional[int] = None

    model_config = {"from_attributes": True}


class UserAchievementOut(BaseModel):
    id: int
    achievement: AchievementOut
    earned_at: datetime

    model_config = {"from_attributes": True}


# ── Home Dashboard ────────────────────────────────────────────────
class HomeDashboard(BaseModel):
    display_name: str
    level: int
    xp: int
    xp_next_level: int
    streak: int
    daily_goal_xp: int
    daily_xp_earned: int
    in_progress_courses: List[CourseWithProgress]
    achievements_count: int
    global_rank: int


# ── Pagination ────────────────────────────────────────────────────
class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    skip: int
    limit: int

    model_config = {"from_attributes": True}


# ── Backoffice Dashboard ──────────────────────────────────────────
class BackofficeDashboard(BaseModel):
    total_users: int
    total_courses: int
    total_modules: int
    total_quizzes: int
    active_users_today: int
    total_quiz_attempts: int
