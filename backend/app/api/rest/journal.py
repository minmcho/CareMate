"""REST endpoints for the private wellness journal."""

from __future__ import annotations

import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser, get_current_user
from app.db.session import get_session
from app.models.wellness import JournalEntryRecord, WellnessProfileRecord
from app.services.audit import log_action
from app.services.encryption import decrypt, encrypt, encrypt_preview
from app.services.safety import scan_user_input

router = APIRouter(prefix="/journal", tags=["journal"])


# ---------------------------------------------------------------------------
# DTOs
# ---------------------------------------------------------------------------


class JournalCreate(BaseModel):
    title: str = Field(max_length=200)
    content: str = Field(max_length=8000)
    mood_score: Optional[int] = Field(default=None, ge=1, le=5)
    tags: List[str] = Field(default_factory=list)


class JournalUpdate(BaseModel):
    title: Optional[str] = Field(default=None, max_length=200)
    content: Optional[str] = Field(default=None, max_length=8000)
    mood_score: Optional[int] = Field(default=None, ge=1, le=5)
    tags: Optional[List[str]] = None


class JournalOut(BaseModel):
    id: str
    title: str
    content_preview: str
    mood_score: Optional[int]
    tags: List[str]
    created_at: str
    updated_at: str


class JournalDetail(JournalOut):
    content: str


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


async def _get_profile(session: AsyncSession, user: CurrentUser) -> WellnessProfileRecord:
    result = await session.execute(
        select(WellnessProfileRecord).where(WellnessProfileRecord.user_id == user.user_id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    return profile


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------


@router.post("", response_model=JournalOut, status_code=status.HTTP_201_CREATED)
async def create_entry(
    body: JournalCreate,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> JournalOut:
    profile = await _get_profile(session, user)
    scan = scan_user_input(body.content)
    entry = JournalEntryRecord(
        profile_id=profile.id,
        title=body.title,
        content_encrypted=encrypt(scan.sanitized),
        content_preview=encrypt_preview(scan.sanitized),
        mood_score=body.mood_score,
        tags=body.tags,
    )
    session.add(entry)
    await log_action(
        session, action="create", resource="journal", user_id=user.user_id,
        resource_id=str(entry.id),
    )
    await session.commit()
    return _to_out(entry)


@router.get("", response_model=List[JournalOut])
async def list_entries(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
    limit: int = 50,
    offset: int = 0,
) -> List[JournalOut]:
    profile = await _get_profile(session, user)
    result = await session.execute(
        select(JournalEntryRecord)
        .where(JournalEntryRecord.profile_id == profile.id)
        .order_by(JournalEntryRecord.created_at.desc())
        .limit(min(limit, 100))
        .offset(offset)
    )
    return [_to_out(e) for e in result.scalars().all()]


@router.get("/{entry_id}", response_model=JournalDetail)
async def get_entry(
    entry_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> JournalDetail:
    profile = await _get_profile(session, user)
    entry = await _fetch_entry(session, entry_id, profile.id)
    return JournalDetail(
        id=str(entry.id),
        title=entry.title,
        content=decrypt(entry.content_encrypted),
        content_preview=decrypt(entry.content_preview),
        mood_score=entry.mood_score,
        tags=entry.tags,
        created_at=entry.created_at.isoformat(),
        updated_at=entry.updated_at.isoformat(),
    )


@router.put("/{entry_id}", response_model=JournalOut)
async def update_entry(
    entry_id: str,
    body: JournalUpdate,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> JournalOut:
    profile = await _get_profile(session, user)
    entry = await _fetch_entry(session, entry_id, profile.id)
    if body.title is not None:
        entry.title = body.title
    if body.content is not None:
        scan = scan_user_input(body.content)
        entry.content_encrypted = encrypt(scan.sanitized)
        entry.content_preview = encrypt_preview(scan.sanitized)
    if body.mood_score is not None:
        entry.mood_score = body.mood_score
    if body.tags is not None:
        entry.tags = body.tags
    await log_action(
        session, action="update", resource="journal", user_id=user.user_id,
        resource_id=entry_id,
    )
    await session.commit()
    return _to_out(entry)


@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_entry(
    entry_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    profile = await _get_profile(session, user)
    entry = await _fetch_entry(session, entry_id, profile.id)
    await log_action(
        session, action="delete", resource="journal", user_id=user.user_id,
        resource_id=entry_id,
    )
    await session.delete(entry)
    await session.commit()


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------


async def _fetch_entry(
    session: AsyncSession, entry_id: str, profile_id: uuid.UUID
) -> JournalEntryRecord:
    result = await session.execute(
        select(JournalEntryRecord).where(
            JournalEntryRecord.id == uuid.UUID(entry_id),
            JournalEntryRecord.profile_id == profile_id,
        )
    )
    entry = result.scalar_one_or_none()
    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entry not found")
    return entry


def _to_out(entry: JournalEntryRecord) -> JournalOut:
    try:
        preview = decrypt(entry.content_preview)
    except Exception:
        preview = ""
    return JournalOut(
        id=str(entry.id),
        title=entry.title,
        content_preview=preview,
        mood_score=entry.mood_score,
        tags=entry.tags,
        created_at=entry.created_at.isoformat(),
        updated_at=entry.updated_at.isoformat(),
    )
