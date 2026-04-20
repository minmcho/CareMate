"""Redis-backed reasoning context window for multi-turn coaching and analytics."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Any

import redis

from app.core.config import get_settings

settings = get_settings()


@dataclass
class ContextEvent:
    event_type: str
    payload: dict[str, Any]
    created_at_iso: str


class ReasoningContextStore:
    """Small Redis list wrapper for short-term reasoning context."""

    def __init__(self, redis_url: str = settings.redis_url):
        self._redis = redis.Redis.from_url(redis_url, decode_responses=True)

    @staticmethod
    def _key(user_id: str) -> str:
        return f"reasoning:{user_id}"

    def append_event(self, user_id: str, event_type: str, payload: dict[str, Any], limit: int = 80) -> None:
        event = ContextEvent(
            event_type=event_type,
            payload=payload,
            created_at_iso=datetime.now(timezone.utc).isoformat(),
        )
        key = self._key(user_id)
        self._redis.lpush(key, json.dumps(asdict(event)))
        self._redis.ltrim(key, 0, max(0, limit - 1))

    def recent_events(self, user_id: str, limit: int = 20) -> list[ContextEvent]:
        key = self._key(user_id)
        rows = self._redis.lrange(key, 0, max(0, limit - 1))
        events: list[ContextEvent] = []
        for row in rows:
            data = json.loads(row)
            events.append(
                ContextEvent(
                    event_type=str(data.get("event_type", "unknown")),
                    payload=dict(data.get("payload", {})),
                    created_at_iso=str(data.get("created_at_iso", "")),
                )
            )
        return events
