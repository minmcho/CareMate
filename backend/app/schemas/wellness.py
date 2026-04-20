"""Pydantic DTOs used on the REST boundary."""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class WellnessProfileIn(BaseModel):
    display_name: str
    preferred_language: str = "en"
    dietary_preferences: List[str] = Field(default_factory=list)
    wellness_goals: List[str] = Field(default_factory=list)
    comforts: List[str] = Field(default_factory=list)
    avoid: List[str] = Field(default_factory=list)


class WellnessProfileOut(WellnessProfileIn):
    id: str
    streak_days: int = 0
    streak_freeze_available: bool = True
    last_check_in_at: Optional[datetime] = None
    created_at: datetime


class ChatRequest(BaseModel):
    text: str
    history: List[dict] = Field(default_factory=list)


class ChatResponseDTO(BaseModel):
    content: str
    agent: str
    crisis_triggered: bool
    safety_rewritten: bool


class VideoAnalysisRequest(BaseModel):
    mode: str  # "meal" | "exercise"
    storage_url: str
    duration_sec: int = 0


class VideoAnalysisOut(BaseModel):
    id: str
    mode: str
    score: int
    safety_flag: bool
    highlights: List[str]
    cautions: List[str]
    nutrition_estimate: Optional[str] = None
    form_notes: Optional[List[str]] = None


# ---------------------------------------------------------------------------
# Sleep
# ---------------------------------------------------------------------------


class SleepRecordIn(BaseModel):
    date_iso: str
    bedtime_iso: Optional[str] = None
    waketime_iso: Optional[str] = None
    duration_min: int = 0
    deep_min: int = 0
    rem_min: int = 0
    light_min: int = 0
    awake_min: int = 0
    source: str = "manual"
    notes: str = ""


class SleepRecordOut(SleepRecordIn):
    id: str
    quality_score: int = 0
    created_at: datetime


# ---------------------------------------------------------------------------
# Mood
# ---------------------------------------------------------------------------


class MoodCheckInIn(BaseModel):
    score: int = Field(ge=1, le=5)
    energy: int = Field(default=3, ge=1, le=5)
    tags: List[str] = Field(default_factory=list)
    note: str = ""


class MoodCheckInOut(MoodCheckInIn):
    id: str
    created_at: datetime


class MoodPatternOut(BaseModel):
    trend: str
    avg_score: float
    avg_energy: float
    top_tags: List[str]
    alert: str


# ---------------------------------------------------------------------------
# Insights
# ---------------------------------------------------------------------------


class WeeklyInsightOut(BaseModel):
    id: str
    week_iso: str
    summary: str
    highlights: List[str]
    suggestions: List[str]
    mood_avg: Optional[float] = None
    sleep_avg_min: Optional[int] = None
    streak_days: int = 0
    agent: str = "deepseek"
    created_at: datetime


# ---------------------------------------------------------------------------
# Challenges
# ---------------------------------------------------------------------------


class ChallengeOut(BaseModel):
    id: str
    title: str
    description: str
    category: str
    icon: str
    target_days: int
    participant_count: int
    is_active: bool
    starts_at: datetime
    ends_at: Optional[datetime] = None
    joined: bool = False
    progress_days: int = 0
