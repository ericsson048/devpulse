"""Seed the database with sample data for DevPulse."""
import asyncio, json
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import async_session, init_db
from app.models import (
    User, UserRole, Course, CourseLevel, Module, Lesson, LessonType,
    Quiz, QuizQuestion, Achievement,
)
from app.auth import hash_password


async def seed():
    await init_db()

    async with async_session() as db:
        # ── Admin user ──────────────────────────────────────────
        admin = User(
            email="admin@devpulse.io",
            hashed_password=hash_password("devpulse2024"),
            display_name="Admin",
            role=UserRole.admin,
            level=1,
            xp=0,
        )
        db.add(admin)

        # ── Demo user ───────────────────────────────────────────
        demo = User(
            email="dev@pulse.io",
            hashed_password=hash_password("password123"),
            display_name="Code Master",
            role=UserRole.user,
            level=42,
            xp=8450,
            streak=7,
        )
        db.add(demo)

        # ── Courses ─────────────────────────────────────────────
        courses_data = [
            ("Backend Engineering", "Master server-side architecture, APIs, and databases", "storage_rounded", "Node.js", CourseLevel.intermediate, "JavaScript", 12, 1200),
            ("Rust Fundamentals", "Learn systems programming with Rust from scratch", "memory_rounded", "Rust", CourseLevel.beginner, "Rust", 8, 800),
            ("TypeScript Patterns", "Advanced design patterns and type-safe architectures", "javascript_rounded", "TypeScript", CourseLevel.advanced, "TypeScript", 10, 1000),
            ("Go for Backend Developers", "Build high-performance backend services in Go", "code_rounded", "Go", CourseLevel.intermediate, "Go", 8, 800),
            ("Docker & Kubernetes", "Container orchestration and DevOps practices", "cloud_queue_rounded", "DevOps", CourseLevel.advanced, "YAML", 12, 1200),
            ("GraphQL Mastery", "Design and implement modern APIs with GraphQL", "hub_rounded", "API", CourseLevel.intermediate, "GraphQL", 6, 600),
            ("Python Fundamentals", "Start your coding journey with Python", "code_rounded", "Python", CourseLevel.beginner, "Python", 10, 500),
            ("C++ Systems Programming", "Low-level programming and memory management", "terminal", "C++", CourseLevel.advanced, "C++", 14, 1400),
        ]

        courses = []
        for i, (title, desc, icon, tag, level, lang, mods, xp) in enumerate(courses_data):
            c = Course(
                title=title, description=desc, icon=icon, tag=tag,
                level=level, language=lang, total_modules=mods,
                total_xp=xp, sort_order=i, is_published=True,
            )
            db.add(c)
            courses.append(c)

        await db.flush()

        # ── Modules & Lessons for first course (Backend Engineering) ──
        modules_data = [
            ("Introduction to Node.js", "Setting up your development environment"),
            ("HTTP & Express Basics", "Building your first REST API"),
            ("Middleware & Routing", "Understanding the request pipeline"),
            ("Database Integration", "Connecting PostgreSQL with Prisma"),
            ("Authentication & Security", "JWT, OAuth, and password hashing"),
            ("Error Handling", "Robust error management patterns"),
            ("Testing Node.js Apps", "Unit and integration testing with Jest"),
            ("WebSocket & Real-Time", "Building real-time features with Socket.io"),
            ("File Uploads & Storage", "Handling multipart data and cloud storage"),
            ("Caching & Performance", "Redis, memoization, and optimization"),
            ("Deployment & CI/CD", "Docker, GitHub Actions, and cloud hosting"),
            ("Capstone Project", "Build a full-stack application"),
        ]

        for i, (m_title, m_desc) in enumerate(modules_data):
            m = Module(
                course_id=courses[0].id, title=m_title, description=m_desc,
                sort_order=i, total_lessons=3, total_xp=100, is_published=True,
            )
            db.add(m)
            await db.flush()

            # Add 3 lessons per module
            lesson_types = [LessonType.theory, LessonType.code, LessonType.quiz]
            for j, lt in enumerate(lesson_types):
                resources_map = {
                    "HTTP & Express Basics": [
                        {"title": "Express.js Official Docs", "url": "https://expressjs.com", "type": "link"},
                        {"title": "MDN Web API Reference", "url": "https://developer.mozilla.org", "type": "link"},
                    ],
                    "Database Integration": [
                        {"title": "PostgreSQL Documentation", "url": "https://postgresql.org/docs", "type": "link"},
                        {"title": "Prisma ORM Guide", "url": "https://prisma.io/docs", "type": "link"},
                    ],
                    "Authentication & Security": [
                        {"title": "JWT Introduction", "url": "https://jwt.io/introduction", "type": "link"},
                        {"title": "OWASP Cheatsheet", "url": "https://cheatsheetseries.owasp.org", "type": "link"},
                    ],
                    "Testing Node.js Apps": [
                        {"title": "Jest Documentation", "url": "https://jestjs.io/docs", "type": "link"},
                        {"title": "Example Repo", "url": "https://github.com/example/testing", "type": "github"},
                    ],
                    "Deployment & CI/CD": [
                        {"title": "Docker Documentation", "url": "https://docs.docker.com", "type": "link"},
                    ],
                }
                resources_json = json.dumps(resources_map.get(m_title, []))
                l = Lesson(
                    module_id=m.id,
                    title=f"{m_title} — {'Theory' if j == 0 else 'Practice' if j == 1 else 'Challenge'}",
                    lesson_type=lt,
                    content=f"Content for {m_title} lesson {j+1}",
                    video_url="https://www.youtube.com/embed/dQw4w9WgXcQ" if j == 0 and m.sort_order < 3 else None,
                    resources=resources_json,
                    sort_order=j,
                    xp_reward=25 + (j * 10),
                    is_published=True,
                )
                db.add(l)

        # ── Sample Quiz ─────────────────────────────────────────
        quiz = Quiz(
            module_id=1, title="Rust Ownership Quiz",
            time_limit_seconds=45, passing_score=0.7,
            xp_reward=250, is_published=True,
        )
        db.add(quiz)
        await db.flush()

        questions = [
            ("What happens when you assign one String variable to another in Rust?",
             'let s1 = String::from("hello");\nlet s2 = s1;',
             "s1 is cloned and both are valid", "s1 is moved to s2 and is no longer valid",
             "s1 becomes a reference to s2", "A compile-time error occurs at the assignment", 1,
             "Rust uses move semantics by default for heap-allocated types like String."),
            ("Which keyword creates an immutable reference?",
             "let r = &x;",
             "&mut", "&", "ref", "*", 1,
             "The & operator creates an immutable borrow."),
            ("What does the Drop trait do?",
             "",
             "It allocates memory", "It deallocates memory when a value goes out of scope",
             "It clones a value", "It serializes data", 1,
             "Drop is Rust's destructor — it runs when a value leaves scope."),
        ]

        for i, (q_text, code, a, b, c, d, correct, explanation) in enumerate(questions):
            q = QuizQuestion(
                quiz_id=quiz.id, question_text=q_text, code_snippet=code or None,
                option_a=a, option_b=b, option_c=c, option_d=d,
                correct_answer=correct, explanation=explanation, sort_order=i,
            )
            db.add(q)

        # ── Achievements ────────────────────────────────────────
        achievements_data = [
            ("C++ Sentinel", "Master of Memory Management", "shield_rounded", "#1E3A5F", "#60A5FA", 100, "course_complete", 1),
            ("Terminal Wiz", "CLI Mastery Level 10", "keyboard_rounded", "#2D1B69", "#A78BFA", 150, "commands_run", 100),
            ("Bug Hunter", "100 Production Issues Resolved", "bug_report_rounded", "#4C1D1D", "#F87171", 200, "bugs_fixed", 100),
            ("First Steps", "Complete your first lesson", "directions_walk", "#1B3A1B", "#4ADE80", 25, "lessons_complete", 1),
            ("Streak Master", "Maintain a 30-day streak", "local_fire_department", "#3A2B1B", "#FB923C", 500, "streak_days", 30),
        ]

        for title, desc, icon, bg, color, xp, cond_type, cond_val in achievements_data:
            a = Achievement(
                title=title, description=desc, icon=icon,
                icon_bg=bg, icon_color=color, xp_reward=xp,
                condition_type=cond_type, condition_value=cond_val,
            )
            db.add(a)

        await db.commit()
        print("Seed data inserted successfully!")
        print(f"  - 2 users (admin + demo)")
        print(f"  - 8 courses")
        print(f"  - 12 modules with 36 lessons")
        print(f"  - 1 quiz with 3 questions")
        print(f"  - 5 achievements")


if __name__ == "__main__":
    asyncio.run(seed())
