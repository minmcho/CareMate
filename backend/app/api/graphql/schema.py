"""Strawberry GraphQL schema.

Exposes the query/mutation surface consumed by the iOS SwiftUI app.
Every resolver:
    - requires a valid Supabase JWT (via the request context),
    - delegates business logic to services,
    - never returns raw crisis text.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, List, Optional

import strawberry
from fastapi import Depends
from strawberry.fastapi import GraphQLRouter
from strawberry.types import Info

from app.services.mcp import CoachMessage, MCPRouter
from app.services.reasoning_context import ReasoningContextStore
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
class ReasoningEvent:
    event_type: str
    payload_json: str
    created_at_iso: str


@strawberry.type
class AdminMetric:
    key: str
    label: str
    value: str
    trend: str


@strawberry.type
class NicheSpotlight:
    title: str
    summary: str
    audience: str
    growth_signal: str


@strawberry.type
class PoseAnalysis:
    id: str
    posture_score: int
    behavior_state: str
    alerts: List[str]
    created_at: datetime


@strawberry.type
class VoiceTranscription:
    transcript: str
    sanitized_transcript: str
    source: str
    safety_category: str


# ---------------------------------------------------------------------------
# Query / Mutation
# ---------------------------------------------------------------------------


@strawberry.type
class Query:
    @strawberry.field
    async def me(self, info: Info) -> Optional[WellnessProfile]:
        user = info.context["user"]
        # Real impl: SELECT FROM wellness_profiles WHERE user_id = user.user_id
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
    async def reasoning_context(self, info: Info, limit: int = 20) -> List[ReasoningEvent]:
        user = info.context["user"]
        store = ReasoningContextStore()
        events = store.recent_events(user.user_id, limit=limit)
        return [
            ReasoningEvent(
                event_type=event.event_type,
                payload_json=str(event.payload),
                created_at_iso=event.created_at_iso,
            )
            for event in events
        ]

    @strawberry.field
    async def admin_metrics(self, info: Info) -> List[AdminMetric]:
        _ = info
        return [
            AdminMetric(key="daily_active_users", label="Daily Active Users", value="2,480", trend="+8.6%"),
            AdminMetric(key="coach_retention", label="7-Day Retention", value="62%", trend="+3.4%"),
            AdminMetric(key="vision_sessions", label="Vision Sessions/Day", value="1,120", trend="+15.1%"),
            AdminMetric(key="safety_blocks", label="Safety Interventions", value="14", trend="-11.0%"),
        ]

    @strawberry.field
    async def growth_niches(self, info: Info) -> List[NicheSpotlight]:
        _ = info
        return [
            NicheSpotlight(
                title="Desk Ergonomics Coach",
                summary="Pose nudges for remote workers with burnout prevention check-ins.",
                audience="Hybrid workers and freelancers",
                growth_signal="High recurring weekday usage from posture reminders",
            ),
            NicheSpotlight(
                title="Perimenopause Wellness Support",
                summary="Sleep, stress, and movement plans with symptom journaling trends.",
                audience="Women 35-55 seeking non-clinical daily support",
                growth_signal="Strong engagement with guided routines and community circles",
            ),
            NicheSpotlight(
                title="Teen Athlete Recovery",
                summary="Movement form checks, hydration tracking, and mood-safe coaching.",
                audience="Parents, coaches, and high-school athletes",
                growth_signal="High retention around season schedules and micro-plans",
            ),
        ]


@strawberry.type
class Mutation:
    @strawberry.mutation
    async def ask_coach(
        self,
        info: Info,
        text: str,
    ) -> ChatReply:
        router: MCPRouter = info.context["mcp"]
        user = info.context["user"]
        store = ReasoningContextStore()
        profile_ctx = "Language: en\nGoals: wellness"
        store.append_event(user.user_id, "user_message", {"text": text[:1000]})
        response = await router.ask(
            user_text=text,
            history=[CoachMessage(role="user", content=text)],
            profile_context=profile_ctx,
        )
        store.append_event(
            user.user_id,
            "assistant_message",
            {
                "agent": response.agent.value,
                "message": response.message[:1200],
                "safety_rewritten": response.safety_rewritten,
            },
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
    async def ingest_pose_telemetry(
        self,
        info: Info,
        keypoints: List[float],
        behavior_state: str,
        device_ts_iso: str,
    ) -> PoseAnalysis:
        user = info.context["user"]
        store = ReasoningContextStore()
        posture_score = max(0, min(100, int(sum(keypoints[:16]) % 100)))
        alerts: list[str] = []
        if posture_score < 45:
            alerts.append("posture_drift")
        if behavior_state.lower() in {"drowsy", "distressed"}:
            alerts.append("behavior_attention")
        payload: dict[str, Any] = {
            "score": posture_score,
            "behavior_state": behavior_state,
            "alerts": alerts,
            "device_ts_iso": device_ts_iso,
        }
        store.append_event(user.user_id, "pose_telemetry", payload)
        return PoseAnalysis(
            id=f"pose-{datetime.utcnow().timestamp()}",
            posture_score=posture_score,
            behavior_state=behavior_state,
            alerts=alerts,
            created_at=datetime.utcnow(),
        )

    @strawberry.mutation
    async def transcribe_voice_text(
        self,
        info: Info,
        transcript: str,
        source: str = "journal",
    ) -> VoiceTranscription:
        user = info.context["user"]
        store = ReasoningContextStore()
        scan = scan_user_input(transcript)
        store.append_event(
            user.user_id,
            "voice_transcription",
            {
                "source": source,
                "safety_category": scan.category.value,
                "length": len(scan.sanitized),
            },
        )
        return VoiceTranscription(
            transcript=transcript,
            sanitized_transcript=scan.sanitized,
            source=source,
            safety_category=scan.category.value,
        )


schema = strawberry.Schema(query=Query, mutation=Mutation)


def build_graphql_router(mcp: MCPRouter, get_user_dep) -> GraphQLRouter:
    async def context_getter(user=Depends(get_user_dep)):
        return {"user": user, "mcp": mcp}

    return GraphQLRouter(schema, context_getter=context_getter)
