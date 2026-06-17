from app.schemas.schemas import *

__all__ = [
    "LoginRequest", "RegisterRequest", "TokenResponse", "ForgotPasswordRequest",
    "UserOut", "UserUpdate", "UserStats",
    "CourseCreate", "CourseUpdate", "CourseOut", "CourseWithProgress",
    "ModuleCreate", "ModuleUpdate", "ModuleOut",
    "LessonCreate", "LessonUpdate", "LessonOut",
    "QuizQuestionCreate", "QuizQuestionOut", "QuizQuestionPlayer",
    "QuizCreate", "QuizOut", "QuizPlayerOut",
    "QuizSubmitAnswer", "QuizSubmitRequest", "QuizSubmitResult",
    "UserProgressOut", "ProgressUpdateRequest",
    "AchievementOut", "UserAchievementOut",
    "HomeDashboard", "BackofficeDashboard",
]
