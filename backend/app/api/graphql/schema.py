"""Strawberry GraphQL schema.

Exposes the query/mutation surface consumed by the iOS SwiftUI app.
Every resolver:
    - requires a valid Supabase JWT (via the request context),
    - delegates business logic to services,
    - never returns raw crisis text.
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional

import strawberry
from fastapi import Depends
from strawberry.fastapi import GraphQLRouter
from strawberry.types import Info

from app.services.mcp import CoachMessage, MCPRouter
from app.services.safety import hash_for_audit, scan_user_input, SafetyCategory


# ---------------------------------------------------------------------------
# Types
# ---------------------------------------------------------------------------


@strawberry.type
class WellnessProfile:
    id: str
    display_name: str
    preferred_language: str
    dietary_preferences: List[str]
    wellness_goals: List[str]
    comforts: List[str]
    avoid: List[str]
    streak_days: int
    streak_freeze_available: bool
    last_check_in_at: Optional[datetime]
    created_at: datetime


@strawberry.type
class ChatReply:
    content: str
    agent: str
    crisis_triggered: bool
    safety_rewritten: bool


@strawberry.type
class VideoAnalysis:
    id: str
    mode: str
    score: int
    safety_flag: bool
    highlights: List[str]
    cautions: List[str]
    nutrition_estimate: Optional[str]
    form_notes: Optional[List[str]]


@strawberry.type
class CrisisAudit:
    id: str
    trigger_hash: str
    language: str
    created_at: datetime


@strawberry.type
class SleepLog:
    id: str
    date_iso: str
    bedtime_iso: Optional[str]
    waketime_iso: Optional[str]
    duration_min: int
    quality_score: int
    deep_min: int
    rem_min: int
    light_min: int
    awake_min: int
    source: str
    notes: str
    created_at: datetime


@strawberry.type
class SleepTrend:
    trend: str
    avg_score: float
    recommendation: str
    data_points: int


@strawberry.type
class MoodCheckIn:
    id: str
    score: int
    energy: int
    tags: List[str]
    note: str
    created_at: datetime


@strawberry.type
class MoodPattern:
    trend: str
    avg_score: float
    avg_energy: float
    top_tags: List[str]
    alert: str


@strawberry.type
class WeeklyInsight:
    id: str
    week_iso: str
    summary: str
    highlights: List[str]
    suggestions: List[str]
    mood_avg: Optional[float]
    sleep_avg_min: Optional[int]
    streak_days: int
    agent: str
    created_at: datetime


@strawberry.type
class Challenge:
    id: str
    title: str
    description: str
    category: str
    icon: str
    target_days: int
    participant_count: int
    is_active: bool
    joined: bool
    progress_days: int


@strawberry.type
class JournalEntry:
    id: str
    title: str
    content_preview: str
    mood_score: Optional[int]
    tags: List[str]
    created_at: datetime
    updated_at: datetime


@strawberry.type
class HabitItem:
    id: str
    title: str
    emoji: str
    goal: str
    target_per_week: int
    completed_this_week: int


@strawberry.type
class CommunityTopicItem:
    id: str
    title: str
    description: str
    category: str
    icon: str
    member_count: int
    is_official: bool


# ---------------------------------------------------------------------------
# Query / Mutation
# ---------------------------------------------------------------------------


@strawberry.type
class Query:
    @strawberry.field
    async def me(self, info: Info) -> Optional[WellnessProfile]:
        user = info.context["user"]
        return WellnessProfile(
            id=user.user_id,
            display_name="Friend",
            preferred_language=user.language,
            dietary_preferences=[],
            wellness_goals=[],
            comforts=[],
            avoid=[],
            streak_days=0,
            streak_freeze_available=True,
            last_check_in_at=None,
            created_at=datetime.utcnow(),
        )

    @strawberry.field
    async def recent_video_analyses(self, info: Info, limit: int = 10) -> List[VideoAnalysis]:
        return []

    @strawberry.field
    async def sleep_logs(self, info: Info, limit: int = 14) -> List[SleepLog]:
        return []

    @strawberry.field
    async def sleep_trend(self, info: Info) -> SleepTrend:
        return SleepTrend(
            trend="insufficient_data", avg_score=0, recommendation="Start logging your sleep to see trends.", data_points=0,
        )

    @strawberry.field
    async def mood_history(self, info: Info, limit: int = 30) -> List[MoodCheckIn]:
        return []

    @strawberry.field
    async def mood_pattern(self, info: Info) -> MoodPattern:
        return MoodPattern(
            trend="insufficient_data", avg_score=0, avg_energy=0, top_tags=[], alert="",
        )

    @strawberry.field
    async def weekly_insights(self, info: Info, limit: int = 12) -> List[WeeklyInsight]:
        return []

    @strawberry.field
    async def challenges(self, info: Info) -> List[Challenge]:
        return []

    @strawberry.field
    async def habits(self, info: Info) -> List[HabitItem]:
        return []

    @strawberry.field
    async def journal_entries(self, info: Info, limit: int = 20) -> List[JournalEntry]:
        return []

    @strawberry.field
    async def community_topics(self, info: Info) -> List[CommunityTopicItem]:
        return []


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def ask_coach(
        self,
        info: Info,
        text: str,
    ) -> ChatReply:
        router: MCPRouter = info.context["mcp"]
        profile_ctx = "Language: en\nGoals: wellness"
        response = await router.ask(
            user_text=text,
            history=[CoachMessage(role="user", content=text)],
            profile_context=profile_ctx,
        )
        return ChatReply(
            content=response.message,
            agent=response.agent.value,
            crisis_triggered=response.crisis_triggered,
            safety_rewritten=response.safety_rewritten,
        )

    @strawberry.mutation
    async def log_crisis(
        self,
        info: Info,
        raw_text: str,
    ) -> CrisisAudit:
        scan = scan_user_input(raw_text)
        language = info.context["user"].language
        return CrisisAudit(
            id="00000000-0000-0000-0000-000000000000",
            trigger_hash=hash_for_audit(raw_text)
            if scan.category == SafetyCategory.CRISIS
            else hash_for_audit("non-crisis"),
            language=language,
            created_at=datetime.utcnow(),
        )

    @strawberry.mutation
    async def log_sleep(
        self,
        info: Info,
        date_iso: str,
        duration_min: int,
        deep_min: int = 0,
        rem_min: int = 0,
        light_min: int = 0,
        awake_min: int = 0,
        bedtime_iso: Optional[str] = None,
        waketime_iso: Optional[str] = None,
        source: str = "manual",
    ) -> SleepLog:
        from app.services.sleep import compute_quality_score
        quality = compute_quality_score(duration_min, deep_min, rem_min, awake_min)
        return SleepLog(
            id="00000000-0000-0000-0000-000000000000",
            date_iso=date_iso,
            bedtime_iso=bedtime_iso,
            waketime_iso=waketime_iso,
            duration_min=duration_min,
            quality_score=quality,
            deep_min=deep_min,
            rem_min=rem_min,
            light_min=light_min,
            awake_min=awake_min,
            source=source,
            notes="",
            created_at=datetime.utcnow(),
        )

    @strawberry.mutation
    async def log_mood(
        self,
        info: Info,
        score: int,
        energy: int = 3,
        tags: Optional[List[str]] = None,
        note: str = "",
    ) -> MoodCheckIn:
        return MoodCheckIn(
            id="00000000-0000-0000-0000-000000000000",
            score=max(1, min(5, score)),
            energy=max(1, min(5, energy)),
            tags=tags or [],
            note=note,
            created_at=datetime.utcnow(),
        )

    @strawberry.mutation
    async def join_challenge(self, info: Info, challenge_id: str) -> bool:
        return True


schema = strawberry.Schema(query=Query, mutation=Mutation)


def build_graphql_router(mcp: MCPRouter, get_user_dep) -> GraphQLRouter:
    async def context_getter(user=Depends(get_user_dep)):
        return {"user": user, "mcp": mcp}

    return GraphQLRouter(schema, context_getter=context_getter)
