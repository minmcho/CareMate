"""
Reasoning Memory Cache — stores conversation context and reasoning chains in Redis
so repeated or similar questions can be answered without re-running full LLM inference.
"""
import hashlib
import json
from typing import Optional, List

import redis.asyncio as aioredis

from app.config import settings


_redis: Optional[aioredis.Redis] = None


async def get_redis() -> aioredis.Redis:
    global _redis
    if _redis is None:
        _redis = await aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
        )
    return _redis


def _make_key(user_id: str, prompt: str, language: str) -> str:
    raw = f"{user_id}:{language}:{prompt.strip().lower()}"
    return "memory:" + hashlib.sha256(raw.encode()).hexdigest()


def _history_key(user_id: str) -> str:
    return f"history:{user_id}"


# ─── Reasoning cache ──────────────────────────────────────────────────────────

async def get_cached_response(user_id: str, prompt: str, language: str) -> Optional[dict]:
    """Return cached reasoning + answer, or None on miss."""
    r = await get_redis()
    key = _make_key(user_id, prompt, language)
    value = await r.get(key)
    if value:
        return json.loads(value)
    return None


async def cache_response(
    user_id: str,
    prompt: str,
    language: str,
    response: dict,
    ttl: int = None,
) -> None:
    """Store reasoning + answer in Redis with TTL."""
    r = await get_redis()
    key = _make_key(user_id, prompt, language)
    await r.setex(key, ttl or settings.MEMORY_CACHE_TTL, json.dumps(response))


async def invalidate_cache(user_id: str, prompt: str, language: str) -> None:
    r = await get_redis()
    key = _make_key(user_id, prompt, language)
    await r.delete(key)


# ─── Conversation history ─────────────────────────────────────────────────────

async def append_to_history(user_id: str, role: str, content: str) -> None:
    """Append a message to the user's rolling conversation history (last 20 turns)."""
    r = await get_redis()
    key = _history_key(user_id)
    entry = json.dumps({"role": role, "content": content})
    await r.rpush(key, entry)
    await r.ltrim(key, -20, -1)  # keep last 20 messages
    await r.expire(key, settings.MEMORY_CACHE_TTL)


async def get_history(user_id: str) -> List[dict]:
    """Retrieve conversation history for a user."""
    r = await get_redis()
    key = _history_key(user_id)
    raw_messages = await r.lrange(key, 0, -1)
    return [json.loads(m) for m in raw_messages]


async def clear_history(user_id: str) -> None:
    r = await get_redis()
    await r.delete(_history_key(user_id))


# ─── Semantic memory (summary) ────────────────────────────────────────────────

async def store_summary(user_id: str, summary: str) -> None:
    """Store a long-term summary of the user's care needs."""
    r = await get_redis()
    key = f"summary:{user_id}"
    await r.set(key, summary, ex=86400 * 7)  # 7 days


async def get_summary(user_id: str) -> Optional[str]:
    r = await get_redis()
    return await r.get(f"summary:{user_id}")
