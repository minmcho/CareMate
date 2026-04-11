"""Celery tasks for long-running AI generation (chat summaries, weekly digests)."""

from __future__ import annotations

import asyncio

from loguru import logger

from app.services.mcp import CoachMessage, MCPRouter
from app.tasks.celery_app import celery_app


@celery_app.task(name="app.tasks.ai_tasks.weekly_digest")
def weekly_digest(profile_id: str, history: list[dict]) -> dict:
    """Generate a gentle weekly summary for the user."""
    logger.info("weekly_digest profile_id={}", profile_id)
    router = MCPRouter()
    try:
        messages = [
            CoachMessage(role=str(m.get("role", "user")), content=str(m.get("content", "")))
            for m in history
        ]
        response = asyncio.run(
            router.ask(
                user_text="Give me a gentle one-paragraph weekly wellness summary.",
                history=messages,
                profile_context="Language: en",
            )
        )
        return {
            "content": response.message,
            "agent": response.agent.value,
            "safety_rewritten": response.safety_rewritten,
        }
    finally:
        asyncio.run(router.aclose())
