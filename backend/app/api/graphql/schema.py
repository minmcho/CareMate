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


schema = strawberry.Schema(query=Query, mutation=Mutation)


def build_graphql_router(mcp: MCPRouter, get_user_dep) -> GraphQLRouter:
    async def context_getter(user=Depends(get_user_dep)):
        return {"user": user, "mcp": mcp}

    return GraphQLRouter(schema, context_getter=context_getter)
