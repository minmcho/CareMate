"""Sleep analytics service — scoring, trends, and AI recommendations."""

from __future__ import annotations

from typing import List, Optional

from loguru import logger


def compute_quality_score(
    duration_min: int,
    deep_min: int = 0,
    rem_min: int = 0,
    awake_min: int = 0,
) -> int:
    score = 0
    if 420 <= duration_min <= 540:
        score += 40
    elif 360 <= duration_min < 420 or 540 < duration_min <= 600:
        score += 25
    elif duration_min > 0:
        score += 10

    if duration_min > 0 and deep_min > 0:
        deep_pct = deep_min / duration_min
        if deep_pct >= 0.15:
            score += 20
        elif deep_pct >= 0.10:
            score += 12
        else:
            score += 5

    if duration_min > 0 and rem_min > 0:
        rem_pct = rem_min / duration_min
        if rem_pct >= 0.20:
            score += 20
        elif rem_pct >= 0.12:
            score += 12
        else:
            score += 5

    if awake_min <= 15:
        score += 20
    elif awake_min <= 30:
        score += 10
    else:
        score += 3

    return min(score, 100)


def sleep_trend(scores: List[int]) -> str:
    if len(scores) < 3:
        return "insufficient_data"
    recent = scores[-3:]
    avg_recent = sum(recent) / len(recent)
    if len(scores) >= 7:
        avg_prior = sum(scores[-7:-3]) / max(len(scores[-7:-3]), 1)
    else:
        avg_prior = avg_recent
    if avg_recent > avg_prior + 5:
        return "improving"
    if avg_recent < avg_prior - 5:
        return "declining"
    return "stable"


def sleep_recommendation(score: int, duration_min: int, deep_min: int) -> str:
    tips = []
    if duration_min < 360:
        tips.append("Try to aim for 7-9 hours of sleep")
    if score < 50:
        tips.append("Consider a consistent bedtime routine")
    if deep_min < 30 and duration_min > 300:
        tips.append("Reduce screen time before bed to improve deep sleep")
    if not tips:
        tips.append("Great sleep quality — keep it up!")
    return ". ".join(tips) + "."
