from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.database import init_db
from app.routers import (
    auth_router,
    users_router,
    courses_router,
    modules_router,
    quizzes_router,
    progress_router,
    media_router,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(
    title="DevPulse API",
    description="Backend API for DevPulse — Unified Development Learning Engine",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routes ────────────────────────────────────────────────────────
app.include_router(auth_router.router, prefix="/api")
app.include_router(users_router.router, prefix="/api")
app.include_router(courses_router.router, prefix="/api")
app.include_router(modules_router.router, prefix="/api")
app.include_router(quizzes_router.router, prefix="/api")
app.include_router(progress_router.router, prefix="/api")
app.include_router(media_router.router, prefix="/api")


@app.get("/")
async def root():
    return {"app": "DevPulse API", "version": "1.0.0", "docs": "/docs"}
