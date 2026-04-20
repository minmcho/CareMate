"""AI-generated insights and challenges REST endpoints."""

from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser, get_current_user
from app.db.session import get_session
from app.models.wellness import (
    ChallengeParticipantRecord,
    ChallengeRecord,
    WeeklyInsightRecord,
    WellnessProfileRecord,
)
from app.schemas.wellness import ChallengeOut, WeeklyInsightOut

router = APIRouter(tags=["insights"])


async def _profile_id(user: CurrentUser, session: AsyncSession):
    result = await session.execute(
        select(WellnessProfileRecord.id).where(
            WellnessProfileRecord.user_id == user.user_id
        )
    )
    pid = result.scalar_one_or_none()
    if pid is None:
        raise HTTPException(404, "Profile not found")
    return pid


@router.get("/insights", response_model=List[WeeklyInsightOut])
async def list_insights(
    limit: int = 12,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    result = await session.execute(
        select(WeeklyInsightRecord)
        .where(WeeklyInsightRecord.profile_id == pid)
        .order_by(WeeklyInsightRecord.created_at.desc())
        .limit(limit)
    )
    rows = result.scalars().all()
    return [
        WeeklyInsightOut(
            id=str(r.id),
            week_iso=r.week_iso,
            summary=r.summary,
            highlights=r.highlights,
            suggestions=r.suggestions,
            mood_avg=r.mood_avg,
            sleep_avg_min=r.sleep_avg_min,
            streak_days=r.streak_days,
            agent=r.agent,
            created_at=r.created_at,
        )
        for r in rows
    ]


@router.get("/challenges", response_model=List[ChallengeOut])
async def list_challenges(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    result = await session.execute(
        select(ChallengeRecord).where(ChallengeRecord.is_active.is_(True))
    )
    challenges = result.scalars().all()
    out = []
    for c in challenges:
        pr = await session.execute(
            select(ChallengeParticipantRecord).where(
                ChallengeParticipantRecord.challenge_id == c.id,
                ChallengeParticipantRecord.profile_id == pid,
            )
        )
        participant = pr.scalar_one_or_none()
        out.append(
            ChallengeOut(
                id=str(c.id),
                title=c.title,
                description=c.description,
                category=c.category,
                icon=c.icon,
                target_days=c.target_days,
                participant_count=c.participant_count,
                is_active=c.is_active,
                starts_at=c.starts_at,
                ends_at=c.ends_at,
                joined=participant is not None,
                progress_days=participant.progress_days if participant else 0,
            )
        )
    return out


@router.post("/challenges/{challenge_id}/join", status_code=204)
async def join_challenge(
    challenge_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    existing = await session.execute(
        select(ChallengeParticipantRecord).where(
            ChallengeParticipantRecord.challenge_id == challenge_id,
            ChallengeParticipantRecord.profile_id == pid,
        )
    )
    if existing.scalar_one_or_none():
        return
    session.add(ChallengeParticipantRecord(challenge_id=challenge_id, profile_id=pid))
    await session.execute(
        select(func.count()).select_from(ChallengeParticipantRecord).where(
            ChallengeParticipantRecord.challenge_id == challenge_id
        )
    )
    await session.commit()


@router.post("/challenges/{challenge_id}/progress", status_code=200)
async def update_progress(
    challenge_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    result = await session.execute(
        select(ChallengeParticipantRecord).where(
            ChallengeParticipantRecord.challenge_id == challenge_id,
            ChallengeParticipantRecord.profile_id == pid,
        )
    )
    participant = result.scalar_one_or_none()
    if not participant:
        raise HTTPException(404, "Not joined")
    challenge = await session.get(ChallengeRecord, challenge_id)
    participant.progress_days += 1
    if challenge and participant.progress_days >= challenge.target_days:
        participant.completed = True
    await session.commit()
    return {"progress_days": participant.progress_days, "completed": participant.completed}
