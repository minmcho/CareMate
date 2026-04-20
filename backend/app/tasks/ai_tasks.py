"""Celery tasks for long-running AI generation."""

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


@celery_app.task(name="app.tasks.ai_tasks.generate_weekly_insight")
def generate_weekly_insight(profile_id: str, week_iso: str, context: dict) -> dict:
    """Generate an AI-powered weekly wellness insight using DeepSeek R1."""
    logger.info("generate_weekly_insight profile_id={} week={}", profile_id, week_iso)
    router = MCPRouter()
    try:
        mood_avg = context.get("mood_avg", 0)
        sleep_avg = context.get("sleep_avg_min", 0)
        streak = context.get("streak_days", 0)
        habits_completed = context.get("habits_completed", 0)
        goals = context.get("goals", [])

        prompt = (
            f"Generate a brief, warm weekly wellness insight for someone with these stats:\n"
            f"- Average mood: {mood_avg}/5\n"
            f"- Average sleep: {sleep_avg} min/night\n"
            f"- Streak: {streak} days\n"
            f"- Habits completed: {habits_completed}\n"
            f"- Goals: {', '.join(goals) if goals else 'general wellness'}\n\n"
            f"Provide: 1) A 2-3 sentence summary, 2) 2-3 highlights, 3) 2-3 actionable suggestions.\n"
            f"Be supportive and specific. Never make medical claims."
        )
        response = asyncio.run(
            router.ask(
                user_text=prompt,
                history=[],
                profile_context=f"Language: en\nGoals: {', '.join(goals)}",
            )
        )
        return {
            "summary": response.message,
            "agent": response.agent.value,
            "mood_avg": mood_avg,
            "sleep_avg_min": sleep_avg,
            "streak_days": streak,
        }
    finally:
        asyncio.run(router.aclose())


@celery_app.task(name="app.tasks.ai_tasks.analyse_mood_trends")
def analyse_mood_trends(profile_id: str, recent_scores: list[int]) -> dict:
    """Analyse mood trends and generate personalised recommendations."""
    logger.info("analyse_mood_trends profile_id={} n={}", profile_id, len(recent_scores))
    from app.services.mood import analyse_mood_pattern
    pattern = analyse_mood_pattern(recent_scores, [], [])
    return {
        "trend": pattern.trend,
        "avg_score": pattern.avg_score,
        "alert": pattern.alert,
    }
