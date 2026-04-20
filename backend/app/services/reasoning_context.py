"""Redis-backed reasoning context window for multi-turn coaching and analytics."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Any

import redis
from loguru import logger

from app.core.config import get_settings

settings = get_settings()
_fallback_events: dict[str, list["ContextEvent"]] = {}


@dataclass
class ContextEvent:
    event_type: str
    payload: dict[str, Any]
    created_at_iso: str


class ReasoningContextStore:
    """Small Redis list wrapper for short-term reasoning context."""

    def __init__(self, redis_url: str = settings.redis_url):
        self._redis = redis.Redis.from_url(redis_url, decode_responses=True)
        self._redis_available = True

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
        if self._redis_available:
            try:
                self._redis.lpush(key, json.dumps(asdict(event)))
                self._redis.ltrim(key, 0, max(0, limit - 1))
                return
            except redis.RedisError:
                self._redis_available = False
                logger.warning("ReasoningContextStore degraded to in-memory fallback")
        items = _fallback_events.setdefault(key, [])
        items.insert(0, event)
        _fallback_events[key] = items[:limit]

    def recent_events(self, user_id: str, limit: int = 20) -> list[ContextEvent]:
        key = self._key(user_id)
        if self._redis_available:
            try:
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
            except redis.RedisError:
                self._redis_available = False
                logger.warning("ReasoningContextStore read fallback activated")
        return _fallback_events.get(key, [])[:limit]

    def status(self) -> str:
        if not self._redis_available:
            return "fallback-memory"
        try:
            ok = self._redis.ping()
            return "redis" if ok else "fallback-memory"
        except redis.RedisError:
            self._redis_available = False
            return "fallback-memory"
