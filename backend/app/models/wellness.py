"""Wellness domain models (profile, sessions, habits, audit)."""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import List, Optional

from sqlalchemy import ARRAY, JSON, Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


def _utcnow() -> datetime:
    return datetime.utcnow()


class WellnessProfileRecord(Base):
    __tablename__ = "wellness_profiles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    display_name: Mapped[str] = mapped_column(String(120))
    preferred_language: Mapped[str] = mapped_column(String(8), default="en")
    dietary_preferences: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    wellness_goals: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    comforts: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    avoid: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    streak_days: Mapped[int] = mapped_column(Integer, default=0)
    streak_freeze_available: Mapped[bool] = mapped_column(Boolean, default=True)
    last_check_in_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)

    sessions: Mapped[List["WellnessSessionRecord"]] = relationship(back_populates="profile")
    habits: Mapped[List["HabitRecord"]] = relationship(back_populates="profile")


class WellnessSessionRecord(Base):
    __tablename__ = "wellness_sessions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE")
    )
    kind: Mapped[str] = mapped_column(String(16))
    title: Mapped[str] = mapped_column(String(160))
    summary: Mapped[str] = mapped_column(String(1024), default="")
    tags: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    mood_before: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    mood_after: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    duration_sec: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)

    profile: Mapped["WellnessProfileRecord"] = relationship(back_populates="sessions")


class HabitRecord(Base):
    __tablename__ = "habits"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE")
    )
    title: Mapped[str] = mapped_column(String(120))
    emoji: Mapped[str] = mapped_column(String(8), default="🌿")
    goal: Mapped[str] = mapped_column(String(24))
    target_per_week: Mapped[int] = mapped_column(Integer, default=3)
    completed_this_week: Mapped[int] = mapped_column(Integer, default=0)
    history: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)

    profile: Mapped["WellnessProfileRecord"] = relationship(back_populates="habits")


class ChatMessageRecord(Base):
    __tablename__ = "chat_messages"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE")
    )
    role: Mapped[str] = mapped_column(String(16))
    content: Mapped[str] = mapped_column(String(4096))
    agent: Mapped[Optional[str]] = mapped_column(String(24), nullable=True)
    safety_flags: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)


class VideoAnalysisRecord(Base):
    __tablename__ = "video_analyses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE")
    )
    mode: Mapped[str] = mapped_column(String(16))
    storage_url: Mapped[str] = mapped_column(String(512))
    result: Mapped[dict] = mapped_column(JSON, default=dict)
    score: Mapped[int] = mapped_column(Integer, default=0)
    safety_flag: Mapped[bool] = mapped_column(Boolean, default=False)
    duration_sec: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)


class CrisisAuditRecord(Base):
    """No raw text — only hashes and coarse metadata."""

    __tablename__ = "crisis_audits"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("wellness_profiles.id", ondelete="SET NULL"),
        nullable=True,
    )
    trigger_hash: Mapped[str] = mapped_column(String(64))
    language: Mapped[str] = mapped_column(String(8), default="en")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)


# ---------------------------------------------------------------------------
# Journaling
# ---------------------------------------------------------------------------


class JournalEntryRecord(Base):
    """Private wellness journal.

    Content is encrypted at-rest via Fernet before persistence
    (see ``app.services.encryption``). The ``content_encrypted`` column
    stores the ciphertext; the plain-text column ``content_preview``
    stores only the first 80 chars for listing UI — also encrypted.
    """

    __tablename__ = "journal_entries"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE")
    )
    title: Mapped[str] = mapped_column(String(200))
    content_encrypted: Mapped[str] = mapped_column(String(16384))
    content_preview: Mapped[str] = mapped_column(String(400), default="")
    mood_score: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    tags: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    is_private: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow, onupdate=_utcnow)

    profile: Mapped["WellnessProfileRecord"] = relationship()


# ---------------------------------------------------------------------------
# Knowledge-sharing community
# ---------------------------------------------------------------------------


class CommunityTopicRecord(Base):
    """Discussion topic — users with shared interests gather here."""

    __tablename__ = "community_topics"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(String(1024), default="")
    category: Mapped[str] = mapped_column(String(32))  # mirrors WellnessGoal
    icon: Mapped[str] = mapped_column(String(8), default="💬")
    member_count: Mapped[int] = mapped_column(Integer, default=0)
    is_official: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)


class CommunityPostRecord(Base):
    """User post inside a topic."""

    __tablename__ = "community_posts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    topic_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("community_topics.id", ondelete="CASCADE"),
        index=True,
    )
    author_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE"),
    )
    content: Mapped[str] = mapped_column(String(4096))
    safety_flags: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    like_count: Mapped[int] = mapped_column(Integer, default=0)
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)

    topic: Mapped["CommunityTopicRecord"] = relationship()
    author: Mapped["WellnessProfileRecord"] = relationship()
    replies: Mapped[List["CommunityReplyRecord"]] = relationship(back_populates="post")


class CommunityReplyRecord(Base):
    """Reply to a community post."""

    __tablename__ = "community_replies"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    post_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("community_posts.id", ondelete="CASCADE"),
        index=True,
    )
    author_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE"),
    )
    content: Mapped[str] = mapped_column(String(2048))
    safety_flags: Mapped[List[str]] = mapped_column(ARRAY(String), default=list)
    is_hidden: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)

    post: Mapped["CommunityPostRecord"] = relationship(back_populates="replies")
    author: Mapped["WellnessProfileRecord"] = relationship()


class TopicMemberRecord(Base):
    """Tracks which users joined which topics."""

    __tablename__ = "topic_members"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    topic_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("community_topics.id", ondelete="CASCADE"),
    )
    profile_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wellness_profiles.id", ondelete="CASCADE"),
    )
    joined_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)


# ---------------------------------------------------------------------------
# Audit log
# ---------------------------------------------------------------------------


class AuditLogRecord(Base):
    """Immutable security audit trail."""

    __tablename__ = "audit_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True, index=True)
    action: Mapped[str] = mapped_column(String(64))
    resource: Mapped[str] = mapped_column(String(64))
    resource_id: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    ip_address: Mapped[Optional[str]] = mapped_column(String(45), nullable=True)
    user_agent: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    details: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
