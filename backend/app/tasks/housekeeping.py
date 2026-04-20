"""Periodic maintenance tasks."""

from __future__ import annotations

from datetime import datetime, timedelta

from loguru import logger
from sqlalchemy import text, create_engine

from app.core.config import get_settings
from app.tasks.celery_app import celery_app

_settings = get_settings()
_sync_url = _settings.database_url.replace("+asyncpg", "")


def _engine():
    return create_engine(_sync_url, pool_pre_ping=True)


@celery_app.task(name="app.tasks.housekeeping.rollup_streaks")
def rollup_streaks() -> int:
    """Reset streak_days to 0 for profiles that missed yesterday's check-in."""
    logger.info("rollup_streaks running")
    cutoff = datetime.utcnow() - timedelta(days=1)
    engine = _engine()
    with engine.begin() as conn:
        result = conn.execute(
            text(
                "UPDATE wellness_profiles SET streak_days = 0 "
                "WHERE (last_check_in_at IS NULL OR last_check_in_at < :cutoff) "
                "AND streak_days > 0"
            ),
            {"cutoff": cutoff},
        )
        count = result.rowcount
    logger.info("rollup_streaks reset {} profiles", count)
    return count


@celery_app.task(name="app.tasks.housekeeping.reset_weekly_counters")
def reset_weekly_counters() -> int:
    """Zero-out habit `completed_this_week` counters every Monday."""
    logger.info("reset_weekly_counters running")
    engine = _engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("UPDATE habits SET completed_this_week = 0 WHERE completed_this_week > 0")
        )
        count = result.rowcount
    logger.info("reset_weekly_counters reset {} habits", count)
    return count


@celery_app.task(name="app.tasks.housekeeping.compact_crisis_audit")
def compact_crisis_audit() -> int:
    """Trim crisis audit entries older than 90 days."""
    logger.info("compact_crisis_audit running")
    cutoff = datetime.utcnow() - timedelta(days=90)
    engine = _engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("DELETE FROM crisis_audits WHERE created_at < :cutoff"),
            {"cutoff": cutoff},
        )
        count = result.rowcount
    logger.info("compact_crisis_audit removed {} rows", count)
    return count


@celery_app.task(name="app.tasks.housekeeping.trigger_weekly_insights")
def trigger_weekly_insights() -> int:
    """Queue weekly insight generation for all active profiles."""
    logger.info("trigger_weekly_insights running")
    from app.tasks.ai_tasks import generate_weekly_insight
    engine = _engine()
    from datetime import date
    week_iso = date.today().isoformat()
    with engine.begin() as conn:
        result = conn.execute(
            text(
                "SELECT id::text, wellness_goals, streak_days "
                "FROM wellness_profiles "
                "WHERE last_check_in_at > :cutoff"
            ),
            {"cutoff": datetime.utcnow() - timedelta(days=14)},
        )
        count = 0
        for row in result:
            generate_weekly_insight.delay(
                row[0], week_iso,
                {"goals": row[1] or [], "streak_days": row[2] or 0},
            )
            count += 1
    logger.info("trigger_weekly_insights queued {} profiles", count)
    return count


@celery_app.task(name="app.tasks.housekeeping.compact_audit_log")
def compact_audit_log() -> int:
    """Trim audit log entries older than 365 days."""
    logger.info("compact_audit_log running")
    cutoff = datetime.utcnow() - timedelta(days=365)
    engine = _engine()
    with engine.begin() as conn:
        result = conn.execute(
            text("DELETE FROM audit_logs WHERE created_at < :cutoff"),
            {"cutoff": cutoff},
        )
        count = result.rowcount
    logger.info("compact_audit_log removed {} rows", count)
    return count
