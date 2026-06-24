import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.database import init_db
from app.limiter import limiter
from app.routers import (
    auth_router,
    users_router,
    courses_router,
    modules_router,
    quizzes_router,
    progress_router,
    media_router,
    achievements_router,
    code_exec_router,
)

logger = logging.getLogger("devpulse")

ORIGINS = [
    "http://localhost:5173",
    "http://localhost:4173",
    "https://devpulse.app",
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    logger.info("Starting DevPulse API")
    await init_db()
    yield
    logger.info("Shutting down DevPulse API")


app = FastAPI(
    title="DevPulse API",
    description="Backend API for DevPulse — Unified Development Learning Engine",
    version="1.0.0",
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    resp = await call_next(request)
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["X-Frame-Options"] = "DENY"
    resp.headers["X-XSS-Protection"] = "1; mode=block"
    resp.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    resp.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return resp


# ── Routes ────────────────────────────────────────────────────────
app.include_router(auth_router.router, prefix="/api")
app.include_router(users_router.router, prefix="/api")
app.include_router(courses_router.router, prefix="/api")
app.include_router(modules_router.router, prefix="/api")
app.include_router(quizzes_router.router, prefix="/api")
app.include_router(progress_router.router, prefix="/api")
app.include_router(media_router.router, prefix="/api")
app.include_router(achievements_router.router, prefix="/api")
app.include_router(code_exec_router.router, prefix="/api")


@app.get("/")
async def root():
    return {"app": "DevPulse API", "version": "1.0.0", "docs": "/docs"}
