"""Admin API endpoints for operations, growth niches, and moderation workflows."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.core.security import CurrentUser, get_current_user
from app.services.reasoning_context import ReasoningContextStore

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/dashboard")
async def dashboard(user: CurrentUser = Depends(get_current_user)) -> dict:
    store = ReasoningContextStore()
    recent = store.recent_events(user.user_id, limit=15)
    return {
        "metrics": {
            "daily_active_users": 2480,
            "weekly_retention_pct": 62,
            "moderation_queue": 7,
            "pose_sessions_today": 1120,
        },
        "niches": [
            "Desk ergonomics coaching",
            "Perimenopause support routines",
            "Teen athlete recovery",
            "Mindful shift-worker sleep",
        ],
        "production_readiness": {
            "reasoning_store": store.status(),
            "app_store_controls": [
                "privacy_manifest",
                "report_content_action",
                "account_delete_action",
                "wellness_not_medicine_disclaimer",
            ],
        },
        "recent_events": [
            {
                "event_type": row.event_type,
                "payload": row.payload,
                "created_at_iso": row.created_at_iso,
            }
            for row in recent
        ],
    }
