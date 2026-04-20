"""Sleep tracking REST endpoints."""

from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser, get_current_user
from app.db.session import get_session
from app.models.wellness import SleepRecord, WellnessProfileRecord
from app.schemas.wellness import SleepRecordIn, SleepRecordOut
from app.services.sleep import compute_quality_score, sleep_recommendation, sleep_trend

router = APIRouter(prefix="/sleep", tags=["sleep"])


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


@router.post("", status_code=201, response_model=SleepRecordOut)
async def log_sleep(
    body: SleepRecordIn,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    quality = compute_quality_score(
        body.duration_min, body.deep_min, body.rem_min, body.awake_min,
    )
    record = SleepRecord(
        profile_id=pid,
        date_iso=body.date_iso,
        bedtime_iso=body.bedtime_iso,
        waketime_iso=body.waketime_iso,
        duration_min=body.duration_min,
        quality_score=quality,
        deep_min=body.deep_min,
        rem_min=body.rem_min,
        light_min=body.light_min,
        awake_min=body.awake_min,
        source=body.source,
        notes=body.notes,
    )
    session.add(record)
    await session.commit()
    await session.refresh(record)
    return SleepRecordOut(
        id=str(record.id),
        date_iso=record.date_iso,
        bedtime_iso=record.bedtime_iso,
        waketime_iso=record.waketime_iso,
        duration_min=record.duration_min,
        quality_score=record.quality_score,
        deep_min=record.deep_min,
        rem_min=record.rem_min,
        light_min=record.light_min,
        awake_min=record.awake_min,
        source=record.source,
        notes=record.notes,
        created_at=record.created_at,
    )


@router.get("", response_model=List[SleepRecordOut])
async def list_sleep(
    limit: int = 30,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    result = await session.execute(
        select(SleepRecord)
        .where(SleepRecord.profile_id == pid)
        .order_by(SleepRecord.date_iso.desc())
        .limit(limit)
    )
    rows = result.scalars().all()
    return [
        SleepRecordOut(
            id=str(r.id),
            date_iso=r.date_iso,
            bedtime_iso=r.bedtime_iso,
            waketime_iso=r.waketime_iso,
            duration_min=r.duration_min,
            quality_score=r.quality_score,
            deep_min=r.deep_min,
            rem_min=r.rem_min,
            light_min=r.light_min,
            awake_min=r.awake_min,
            source=r.source,
            notes=r.notes,
            created_at=r.created_at,
        )
        for r in rows
    ]


@router.get("/trend")
async def get_sleep_trend(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    pid = await _profile_id(user, session)
    result = await session.execute(
        select(SleepRecord.quality_score, SleepRecord.duration_min, SleepRecord.deep_min)
        .where(SleepRecord.profile_id == pid)
        .order_by(SleepRecord.date_iso.desc())
        .limit(14)
    )
    rows = list(result.all())
    scores = [r[0] for r in reversed(rows)]
    trend = sleep_trend(scores)
    latest = rows[0] if rows else None
    rec = sleep_recommendation(
        latest[0] if latest else 0,
        latest[1] if latest else 0,
        latest[2] if latest else 0,
    )
    return {
        "trend": trend,
        "avg_score": round(sum(scores) / len(scores), 1) if scores else 0,
        "recommendation": rec,
        "data_points": len(scores),
    }
