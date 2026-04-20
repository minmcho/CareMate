"""Mood tracking REST endpoints."""

from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser, get_current_user
from app.db.session import get_session
from app.models.wellness import MoodCheckInRecord, WellnessProfileRecord
from app.schemas.wellness import MoodCheckInIn, MoodCheckInOut, MoodPatternOut
from app.services.mood import analyse_mood_pattern

router = APIRouter(prefix="/mood", tags=["mood"])


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


@router.post("", status_code=201, response_model=MoodCheckInOut)
async def log_mood(
    body: MoodCheckInIn,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    record = MoodCheckInRecord(
        profile_id=pid,
        score=body.score,
        energy=body.energy,
        tags=body.tags,
        note=body.note,
    )
    session.add(record)
    await session.commit()
    await session.refresh(record)
    return MoodCheckInOut(
        id=str(record.id),
        score=record.score,
        energy=record.energy,
        tags=record.tags,
        note=record.note,
        created_at=record.created_at,
    )


@router.get("", response_model=List[MoodCheckInOut])
async def list_moods(
    limit: int = 30,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    result = await session.execute(
        select(MoodCheckInRecord)
        .where(MoodCheckInRecord.profile_id == pid)
        .order_by(MoodCheckInRecord.created_at.desc())
        .limit(limit)
    )
    rows = result.scalars().all()
    return [
        MoodCheckInOut(
            id=str(r.id),
            score=r.score,
            energy=r.energy,
            tags=r.tags,
            note=r.note,
            created_at=r.created_at,
        )
        for r in rows
    ]


@router.get("/pattern", response_model=MoodPatternOut)
async def get_mood_pattern(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    result = await session.execute(
        select(
            MoodCheckInRecord.score,
            MoodCheckInRecord.energy,
            MoodCheckInRecord.tags,
        )
        .where(MoodCheckInRecord.profile_id == pid)
        .order_by(MoodCheckInRecord.created_at.desc())
        .limit(30)
    )
    rows = list(result.all())
    scores = [r[0] for r in reversed(rows)]
    energies = [r[1] for r in reversed(rows)]
    tags_lists = [r[2] for r in reversed(rows)]
    pattern = analyse_mood_pattern(scores, energies, tags_lists)
    return MoodPatternOut(
        trend=pattern.trend,
        avg_score=pattern.avg_score,
        avg_energy=pattern.avg_energy,
        top_tags=pattern.top_tags,
        alert=pattern.alert,
    )
