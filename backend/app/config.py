from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str = "devpulse-secret"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    BACKOFFICE_USERNAME: str = "admin"
    BACKOFFICE_PASSWORD: str = "devpulse2024"
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USERNAME: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM: str = "noreply@devpulse.io"
    APP_URL: str = "http://localhost:5173"

    @property
    def async_database_url(self) -> str:
        # asyncpg uses 'ssl' instead of 'sslmode'
        return self.DATABASE_URL.replace("sslmode=require", "ssl=require")

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
