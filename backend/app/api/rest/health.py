"""Health and readiness probes."""

from fastapi import APIRouter

from app.core.config import get_settings
from app.services.reasoning_context import ReasoningContextStore

router = APIRouter(tags=["ops"])
settings = get_settings()


@router.get("/healthz")
async def healthz() -> dict:
    return {"status": "ok"}


@router.get("/readyz")
async def readyz() -> dict:
    reasoning = ReasoningContextStore()
    redis_status = reasoning.status()
    supabase_ready = bool(settings.supabase_url and settings.supabase_jwt_secret)
    status = "ready" if (supabase_ready and redis_status in {"redis", "fallback-memory"}) else "degraded"
    return {
        "status": status,
        "checks": {
            "supabase_auth_configured": supabase_ready,
            "reasoning_store": redis_status,
            "database_url_configured": bool(settings.database_url),
            "celery_broker_configured": bool(settings.celery_broker_url),
        },
    }
