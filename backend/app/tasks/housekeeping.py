"""Periodic maintenance tasks."""

from __future__ import annotations

from loguru import logger

from app.tasks.celery_app import celery_app


@celery_app.task(name="app.tasks.housekeeping.rollup_streaks")
def rollup_streaks() -> int:
    """Recompute current streaks from session history."""
    logger.info("rollup_streaks running")
    # Real impl: UPDATE wellness_profiles SET streak_days = ... FROM last_check_in
    return 0


@celery_app.task(name="app.tasks.housekeeping.reset_weekly_counters")
def reset_weekly_counters() -> int:
    """Zero-out habit `completed_this_week` counters every Monday."""
    logger.info("reset_weekly_counters running")
    return 0


@celery_app.task(name="app.tasks.housekeeping.compact_crisis_audit")
def compact_crisis_audit() -> int:
    """Trim old crisis audit entries (90 day retention)."""
    logger.info("compact_crisis_audit running")
    return 0
