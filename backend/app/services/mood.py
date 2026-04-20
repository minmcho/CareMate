"""Mood pattern analysis service — trends, triggers, and alerts."""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Tuple


@dataclass
class MoodPattern:
    trend: str
    avg_score: float
    avg_energy: float
    top_tags: List[str]
    alert: str


def analyse_mood_pattern(
    scores: List[int],
    energies: List[int],
    tags_lists: List[List[str]],
) -> MoodPattern:
    if not scores:
        return MoodPattern(
            trend="insufficient_data",
            avg_score=0,
            avg_energy=0,
            top_tags=[],
            alert="",
        )

    avg_score = sum(scores) / len(scores)
    avg_energy = sum(energies) / len(energies) if energies else 3.0

    if len(scores) >= 3:
        recent = scores[-3:]
        avg_recent = sum(recent) / len(recent)
        if avg_recent >= 4.0:
            trend = "positive"
        elif avg_recent <= 2.0:
            trend = "low"
        elif len(scores) >= 5:
            older = scores[-5:-3]
            avg_older = sum(older) / len(older) if older else avg_recent
            if avg_recent > avg_older + 0.5:
                trend = "improving"
            elif avg_recent < avg_older - 0.5:
                trend = "declining"
            else:
                trend = "stable"
        else:
            trend = "stable"
    else:
        trend = "stable"

    tag_counts: dict[str, int] = {}
    for tl in tags_lists:
        for tag in tl:
            tag_counts[tag] = tag_counts.get(tag, 0) + 1
    top_tags = sorted(tag_counts, key=lambda t: tag_counts[t], reverse=True)[:5]

    alert = ""
    if trend == "low" and avg_score <= 2.0:
        alert = "Your mood has been consistently low. Consider talking to someone you trust."
    elif trend == "declining":
        alert = "Your mood appears to be trending downward. A breathwork session may help."

    return MoodPattern(
        trend=trend,
        avg_score=round(avg_score, 1),
        avg_energy=round(avg_energy, 1),
        top_tags=top_tags,
        alert=alert,
    )


MOOD_TAGS = [
    "grateful", "anxious", "calm", "tired", "energized",
    "focused", "stressed", "happy", "sad", "motivated",
    "overwhelmed", "peaceful", "irritable", "hopeful", "lonely",
]
