from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    # MongoDB
    MONGODB_URL: str = "mongodb://localhost:27017"
    MONGODB_DB_NAME: str = "caremate"

    # VLLM
    VLLM_BASE_URL: str = "http://localhost:8000/v1"
    VLLM_MODEL: str = "mistralai/Mistral-7B-Instruct-v0.3"

    # Speech-to-Text (Whisper)
    STT_MODEL: str = "openai/whisper-large-v3"
    STT_DEVICE: str = "cuda"  # or "cpu"

    # Memory Cache (Redis)
    REDIS_URL: str = "redis://localhost:6379"
    MEMORY_CACHE_TTL: int = 3600  # seconds

    # CrewAI / LLM
    OPENAI_API_KEY: str = ""        # used as fallback or for CrewAI
    ANTHROPIC_API_KEY: str = ""

    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "*"]

    # JWT
    SECRET_KEY: str = "change-me-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours

    class Config:
        env_file = ".env"


settings = Settings()
