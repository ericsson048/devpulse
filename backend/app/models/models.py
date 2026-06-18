from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Text, Float, Enum as SAEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum


class UserRole(str, enum.Enum):
    user = "user"
    admin = "admin"


class CourseLevel(str, enum.Enum):
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"


class LessonType(str, enum.Enum):
    theory = "theory"
    code = "code"
    quiz = "quiz"


# ── User ──────────────────────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    display_name = Column(String(100), nullable=False, default="Developer")
    avatar_url = Column(String(500), nullable=True)
    role = Column(SAEnum(UserRole), default=UserRole.user, nullable=False)
    level = Column(Integer, default=1)
    xp = Column(Integer, default=0)
    streak = Column(Integer, default=0)
    last_active = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    progress = relationship("UserProgress", back_populates="user", cascade="all, delete-orphan")
    quiz_attempts = relationship("QuizAttempt", back_populates="user", cascade="all, delete-orphan")
    achievements = relationship("UserAchievement", back_populates="user", cascade="all, delete-orphan")
    reset_token = Column(String(255), nullable=True)
    reset_token_expires = Column(DateTime(timezone=True), nullable=True)


# ── Course ────────────────────────────────────────────────────────
class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    icon = Column(String(100), nullable=True)
    tag = Column(String(50), nullable=True)
    level = Column(SAEnum(CourseLevel), default=CourseLevel.beginner)
    language = Column(String(50), nullable=True)
    total_modules = Column(Integer, default=0)
    total_xp = Column(Integer, default=0)
    sort_order = Column(Integer, default=0)
    is_published = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    modules = relationship("Module", back_populates="course", cascade="all, delete-orphan")


# ── Module ────────────────────────────────────────────────────────
class Module(Base):
    __tablename__ = "modules"

    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    sort_order = Column(Integer, default=0)
    total_lessons = Column(Integer, default=0)
    total_xp = Column(Integer, default=0)
    is_published = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    course = relationship("Course", back_populates="modules")
    lessons = relationship("Lesson", back_populates="module", cascade="all, delete-orphan")


# ── Lesson ────────────────────────────────────────────────────────
class Lesson(Base):
    __tablename__ = "lessons"

    id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("modules.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    lesson_type = Column(SAEnum(LessonType), default=LessonType.theory)
    # Markdown content — rendered on the client side
    content = Column(Text, nullable=True)
    # Optional video URL (YouTube embed, direct mp4, etc.)
    video_url = Column(String(1000), nullable=True)
    # JSON array of resource links: [{"title": str, "url": str, "type": "pdf"|"link"|"github"}]
    resources = Column(Text, nullable=True)
    # Code editor fields
    code_template = Column(Text, nullable=True)
    code_solution = Column(Text, nullable=True)
    code_language = Column(String(50), nullable=True)   # python, javascript, dart…
    has_editor = Column(Boolean, default=False)          # show inline editor to learner
    sort_order = Column(Integer, default=0)
    xp_reward = Column(Integer, default=25)
    is_published = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    module = relationship("Module", back_populates="lessons")


# ── Quiz ──────────────────────────────────────────────────────────
class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("modules.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    time_limit_seconds = Column(Integer, default=45)
    passing_score = Column(Float, default=0.7)
    xp_reward = Column(Integer, default=250)
    is_published = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    questions = relationship("QuizQuestion", back_populates="quiz", cascade="all, delete-orphan")


class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(Integer, primary_key=True, index=True)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False)
    question_text = Column(Text, nullable=False)
    code_snippet = Column(Text, nullable=True)
    option_a = Column(String(500), nullable=False)
    option_b = Column(String(500), nullable=False)
    option_c = Column(String(500), nullable=False)
    option_d = Column(String(500), nullable=False)
    correct_answer = Column(Integer, nullable=False)  # 0=A, 1=B, 2=C, 3=D
    explanation = Column(Text, nullable=True)
    sort_order = Column(Integer, default=0)

    quiz = relationship("Quiz", back_populates="questions")


# ── User Progress ─────────────────────────────────────────────────
class UserProgress(Base):
    __tablename__ = "user_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id", ondelete="CASCADE"), nullable=False)
    module_id = Column(Integer, ForeignKey("modules.id", ondelete="SET NULL"), nullable=True)
    lesson_id = Column(Integer, ForeignKey("lessons.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(20), default="not_started")  # not_started, in_progress, completed
    progress_percent = Column(Float, default=0.0)
    xp_earned = Column(Integer, default=0)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="progress")


# ── Quiz Attempt ──────────────────────────────────────────────────
class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    quiz_id = Column(Integer, ForeignKey("quizzes.id", ondelete="CASCADE"), nullable=False)
    score = Column(Integer, nullable=False)
    total_questions = Column(Integer, nullable=False)
    xp_earned = Column(Integer, default=0)
    passed = Column(Boolean, default=False)
    answers = Column(Text, nullable=True)  # JSON string of user answers
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="quiz_attempts")


# ── Achievement ───────────────────────────────────────────────────
class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    icon = Column(String(100), nullable=True)
    icon_bg = Column(String(20), nullable=True)
    icon_color = Column(String(20), nullable=True)
    xp_reward = Column(Integer, default=0)
    condition_type = Column(String(50), nullable=True)
    condition_value = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class UserAchievement(Base):
    __tablename__ = "user_achievements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id = Column(Integer, ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False)
    earned_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="achievements")
    achievement = relationship("Achievement")
