"""Application settings loaded from the environment."""

from functools import lru_cache
from typing import List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Typed settings driven by `.env` / environment variables."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "VitalPath AI"
    environment: str = Field(default="development")
    debug: bool = Field(default=True)

    # --- Database -------------------------------------------------------
    database_url: str = Field(
        default="postgresql+asyncpg://vitalpath:vitalpath@localhost:5432/vitalpath"
    )
    # --- Redis / Celery -------------------------------------------------
    redis_url: str = Field(default="redis://localhost:6379/0")
    celery_broker_url: str = Field(default="redis://localhost:6379/1")
    celery_result_backend: str = Field(default="redis://localhost:6379/2")

    # --- ChromaDB -------------------------------------------------------
    chroma_host: str = Field(default="localhost")
    chroma_port: int = Field(default=8001)
    chroma_collection: str = Field(default="user_wellness_context")

    # --- Supabase auth --------------------------------------------------
    supabase_url: str = Field(default="")
    supabase_anon_key: str = Field(default="")
    supabase_jwt_secret: str = Field(default="change-me")

    # --- Model endpoints ------------------------------------------------
    llama4_endpoint: str = Field(default="http://localhost:11434/api/generate")
    llama4_model: str = Field(default="llama-4-8b-instruct")
    qwen_text_endpoint: str = Field(default="http://localhost:11435/api/generate")
    qwen_text_model: str = Field(default="qwen3.5-32b")
    qwen_vl_endpoint: str = Field(default="http://localhost:11436/api/generate")
    qwen_vl_model: str = Field(default="qwen3.5-vl-7b")

    # --- Safety ---------------------------------------------------------
    enable_crisis_escalation: bool = Field(default=True)
    enable_medical_rewrite: bool = Field(default=True)

    # --- Encryption at rest --------------------------------------------
    encryption_key: str = Field(default="change-me-generate-with-fernet")

    # --- Rate limiting --------------------------------------------------
    rate_limit_window: int = Field(default=60)
    rate_limit_max: int = Field(default=120)

    # --- CORS -----------------------------------------------------------
    cors_origins: List[str] = Field(
        default_factory=lambda: ["http://localhost:3000", "http://localhost:8080"]
    )


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
