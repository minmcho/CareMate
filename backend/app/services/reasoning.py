"""Redis-backed reasoning context for multi-turn AI conversations.

Stores per-user conversation context and reasoning chains in Redis with
configurable TTL, enabling the AI to maintain coherent multi-turn
reasoning across requests without bloating the prompt.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from typing import List, Optional

from loguru import logger

try:
    import redis
except Exception:
    redis = None  # type: ignore

from app.core.config import get_settings


@dataclass
class ReasoningTurn:
    role: str
    content: str
    agent: str = ""
    reasoning_trace: str = ""


@dataclass
class ReasoningContext:
    user_id: str
    turns: List[ReasoningTurn]
    active_goals: List[str]
    mood_trend: str = "stable"
    sleep_trend: str = "stable"


class ReasoningContextManager:
    """Per-user reasoning context stored in Redis."""

    def __init__(self) -> None:
        settings = get_settings()
        self._ttl = settings.reasoning_context_ttl
        self._max_turns = settings.reasoning_max_turns
        self._client: Optional[object] = None
        if redis is None:
            logger.info("Redis library not available — reasoning context disabled")
            return
        try:
            self._client = redis.Redis.from_url(
                settings.redis_url, decode_responses=True
            )
            self._client.ping()
        except Exception as exc:
            logger.warning("Redis unavailable for reasoning context: {}", exc)
            self._client = None

    def _key(self, user_id: str) -> str:
        return f"vitalpath:reasoning:{user_id}"

    def get_context(self, user_id: str) -> ReasoningContext:
        if self._client is None:
            return ReasoningContext(user_id=user_id, turns=[], active_goals=[])
        try:
            raw = self._client.get(self._key(user_id))
            if not raw:
                return ReasoningContext(user_id=user_id, turns=[], active_goals=[])
            data = json.loads(raw)
            turns = [ReasoningTurn(**t) for t in data.get("turns", [])]
            return ReasoningContext(
                user_id=user_id,
                turns=turns,
                active_goals=data.get("active_goals", []),
                mood_trend=data.get("mood_trend", "stable"),
                sleep_trend=data.get("sleep_trend", "stable"),
            )
        except Exception as exc:
            logger.warning("Failed to read reasoning context: {}", exc)
            return ReasoningContext(user_id=user_id, turns=[], active_goals=[])

    def append_turn(
        self,
        user_id: str,
        role: str,
        content: str,
        agent: str = "",
        reasoning_trace: str = "",
    ) -> None:
        ctx = self.get_context(user_id)
        ctx.turns.append(
            ReasoningTurn(
                role=role, content=content, agent=agent, reasoning_trace=reasoning_trace,
            )
        )
        if len(ctx.turns) > self._max_turns:
            ctx.turns = ctx.turns[-self._max_turns :]
        self._save(ctx)

    def update_trends(
        self,
        user_id: str,
        mood_trend: str = "",
        sleep_trend: str = "",
        active_goals: Optional[List[str]] = None,
    ) -> None:
        ctx = self.get_context(user_id)
        if mood_trend:
            ctx.mood_trend = mood_trend
        if sleep_trend:
            ctx.sleep_trend = sleep_trend
        if active_goals is not None:
            ctx.active_goals = active_goals
        self._save(ctx)

    def build_prompt_context(self, user_id: str) -> str:
        ctx = self.get_context(user_id)
        parts = []
        if ctx.active_goals:
            parts.append(f"Active goals: {', '.join(ctx.active_goals)}")
        if ctx.mood_trend != "stable":
            parts.append(f"Mood trend: {ctx.mood_trend}")
        if ctx.sleep_trend != "stable":
            parts.append(f"Sleep trend: {ctx.sleep_trend}")
        recent = ctx.turns[-6:]
        if recent:
            memory_lines = []
            for t in recent:
                prefix = t.role.upper()
                memory_lines.append(f"{prefix}: {t.content[:200]}")
            parts.append("Recent context:\n" + "\n".join(memory_lines))
        return "\n".join(parts) if parts else ""

    def clear(self, user_id: str) -> None:
        if self._client is None:
            return
        try:
            self._client.delete(self._key(user_id))
        except Exception:
            pass

    def _save(self, ctx: ReasoningContext) -> None:
        if self._client is None:
            return
        try:
            data = {
                "turns": [asdict(t) for t in ctx.turns],
                "active_goals": ctx.active_goals,
                "mood_trend": ctx.mood_trend,
                "sleep_trend": ctx.sleep_trend,
            }
            self._client.setex(self._key(ctx.user_id), self._ttl, json.dumps(data))
        except Exception as exc:
            logger.warning("Failed to save reasoning context: {}", exc)
