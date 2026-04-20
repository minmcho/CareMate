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


class VoiceTranscribeRequest(BaseModel):
    transcript: str
    source: str = "journal"  # journal | community


class VoiceTranscribeResponse(BaseModel):
    transcript: str
    sanitized_transcript: str
    source: str
    safety_category: str
