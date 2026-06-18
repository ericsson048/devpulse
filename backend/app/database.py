import sqlalchemy as sa
from sqlalchemy import text, inspect as sa_inspect
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from sqlalchemy.orm import DeclarativeBase
from app.config import get_settings

settings = get_settings()

engine = create_async_engine(
    settings.async_database_url,
    echo=False,
    pool_size=5,
    max_overflow=10,
    pool_pre_ping=True,
    pool_recycle=3600,
)

async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


def _type_for_column(col) -> str:
    """Map SQLAlchemy column types to PostgreSQL type strings."""
    t = col.type
    if isinstance(t, sa.String):
        return f"VARCHAR({t.length or 255})"
    if isinstance(t, sa.Integer):
        return "INTEGER"
    if isinstance(t, sa.Boolean):
        return "BOOLEAN"
    if isinstance(t, sa.Float):
        return "FLOAT"
    if isinstance(t, sa.Text):
        return "TEXT"
    if isinstance(t, sa.DateTime):
        if t.timezone:
            return "TIMESTAMPTZ"
        return "TIMESTAMP"
    return "VARCHAR(255)"


def _migrate_schema(sync_conn):
    """Compare model columns vs DB columns and add any missing ones."""
    from app.models.models import User, Course, Module, Lesson, Quiz, QuizQuestion, UserProgress, QuizAttempt, Achievement, UserAchievement

    inspector = sa_inspect(sync_conn)
    for table in Base.metadata.sorted_tables:
        table_name = table.name
        if not inspector.has_table(table_name):
            continue
        existing_cols = {c["name"] for c in inspector.get_columns(table_name)}
        for col in table.columns:
            if col.name not in existing_cols:
                stmt = f"ALTER TABLE {table_name} ADD COLUMN {col.name} {_type_for_column(col)}"
                sync_conn.execute(text(stmt))


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_migrate_schema)
