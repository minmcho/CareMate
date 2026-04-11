"""Celery application factory."""

from celery import Celery
from celery.schedules import crontab

from app.core.config import get_settings

settings = get_settings()

celery_app = Celery(
    "vitalpath",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=[
        "app.tasks.video_tasks",
        "app.tasks.ai_tasks",
        "app.tasks.housekeeping",
    ],
)

celery_app.conf.update(
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    task_time_limit=180,
    task_soft_time_limit=120,
    worker_concurrency=4,
    result_expires=3600,
)

celery_app.conf.beat_schedule = {
    "nightly-streak-rollup": {
        "task": "app.tasks.housekeeping.rollup_streaks",
        "schedule": crontab(hour=3, minute=0),
    },
    "weekly-habit-reset": {
        "task": "app.tasks.housekeeping.reset_weekly_counters",
        "schedule": crontab(day_of_week="mon", hour=0, minute=5),
    },
    "hourly-audit-compaction": {
        "task": "app.tasks.housekeeping.compact_crisis_audit",
        "schedule": crontab(minute=15),
    },
}
