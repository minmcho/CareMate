"""REST endpoints for knowledge-sharing community."""

from __future__ import annotations

import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import CurrentUser, get_current_user
from app.db.session import get_session
from app.models.wellness import (
    CommunityPostRecord,
    CommunityReplyRecord,
    CommunityTopicRecord,
    TopicMemberRecord,
    WellnessProfileRecord,
)
from app.services.audit import log_action
from app.services.safety import scan_user_input

router = APIRouter(prefix="/community", tags=["community"])


# ---------------------------------------------------------------------------
# DTOs
# ---------------------------------------------------------------------------


class TopicOut(BaseModel):
    id: str
    title: str
    description: str
    category: str
    icon: str
    member_count: int
    is_official: bool
    joined: bool = False


class PostCreate(BaseModel):
    content: str = Field(max_length=4000)


class PostOut(BaseModel):
    id: str
    topic_id: str
    author_name: str
    content: str
    like_count: int
    reply_count: int
    safety_flags: List[str]
    created_at: str


class ReplyCreate(BaseModel):
    content: str = Field(max_length=2000)


class ReplyOut(BaseModel):
    id: str
    post_id: str
    author_name: str
    content: str
    created_at: str


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
# Topics
# ---------------------------------------------------------------------------


@router.get("/topics", response_model=List[TopicOut])
async def list_topics(
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
    category: Optional[str] = None,
) -> List[TopicOut]:
    profile = await _get_profile(session, user)
    q = select(CommunityTopicRecord).order_by(CommunityTopicRecord.member_count.desc())
    if category:
        q = q.where(CommunityTopicRecord.category == category)
    result = await session.execute(q.limit(50))
    topics = result.scalars().all()

    # Check which topics the user already joined
    member_result = await session.execute(
        select(TopicMemberRecord.topic_id).where(TopicMemberRecord.profile_id == profile.id)
    )
    joined_ids = {r for r in member_result.scalars().all()}

    return [
        TopicOut(
            id=str(t.id), title=t.title, description=t.description,
            category=t.category, icon=t.icon, member_count=t.member_count,
            is_official=t.is_official, joined=t.id in joined_ids,
        )
        for t in topics
    ]


@router.post("/topics/{topic_id}/join", status_code=status.HTTP_204_NO_CONTENT)
async def join_topic(
    topic_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    profile = await _get_profile(session, user)
    tid = uuid.UUID(topic_id)
    existing = await session.execute(
        select(TopicMemberRecord).where(
            TopicMemberRecord.topic_id == tid,
            TopicMemberRecord.profile_id == profile.id,
        )
    )
    if existing.scalar_one_or_none():
        return
    session.add(TopicMemberRecord(topic_id=tid, profile_id=profile.id))
    await session.execute(
        CommunityTopicRecord.__table__.update()
        .where(CommunityTopicRecord.id == tid)
        .values(member_count=CommunityTopicRecord.member_count + 1)
    )
    await log_action(
        session, action="join", resource="topic", user_id=user.user_id, resource_id=topic_id,
    )
    await session.commit()


@router.post("/topics/{topic_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
async def leave_topic(
    topic_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    profile = await _get_profile(session, user)
    tid = uuid.UUID(topic_id)
    result = await session.execute(
        select(TopicMemberRecord).where(
            TopicMemberRecord.topic_id == tid,
            TopicMemberRecord.profile_id == profile.id,
        )
    )
    membership = result.scalar_one_or_none()
    if not membership:
        return
    await session.delete(membership)
    await session.execute(
        CommunityTopicRecord.__table__.update()
        .where(CommunityTopicRecord.id == tid)
        .values(member_count=func.greatest(CommunityTopicRecord.member_count - 1, 0))
    )
    await session.commit()


# ---------------------------------------------------------------------------
# Posts
# ---------------------------------------------------------------------------


@router.get("/topics/{topic_id}/posts", response_model=List[PostOut])
async def list_posts(
    topic_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
    limit: int = 30,
    offset: int = 0,
) -> List[PostOut]:
    tid = uuid.UUID(topic_id)
    result = await session.execute(
        select(CommunityPostRecord)
        .where(CommunityPostRecord.topic_id == tid, CommunityPostRecord.is_hidden == False)
        .order_by(CommunityPostRecord.created_at.desc())
        .limit(min(limit, 100))
        .offset(offset)
    )
    posts = result.scalars().all()
    out: List[PostOut] = []
    for p in posts:
        author = await session.get(WellnessProfileRecord, p.author_id)
        reply_count_result = await session.execute(
            select(func.count()).where(CommunityReplyRecord.post_id == p.id)
        )
        out.append(PostOut(
            id=str(p.id), topic_id=str(p.topic_id),
            author_name=author.display_name if author else "Anonymous",
            content=p.content, like_count=p.like_count,
            reply_count=reply_count_result.scalar() or 0,
            safety_flags=p.safety_flags, created_at=p.created_at.isoformat(),
        ))
    return out


@router.post("/topics/{topic_id}/posts", response_model=PostOut, status_code=status.HTTP_201_CREATED)
async def create_post(
    topic_id: str,
    body: PostCreate,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> PostOut:
    profile = await _get_profile(session, user)
    scan = scan_user_input(body.content)
    post = CommunityPostRecord(
        topic_id=uuid.UUID(topic_id),
        author_id=profile.id,
        content=scan.sanitized,
        safety_flags=[scan.category.value] if not scan.passed else [],
        is_hidden=scan.category.value == "crisis",
    )
    session.add(post)
    await log_action(
        session, action="create", resource="post", user_id=user.user_id,
        resource_id=str(post.id),
    )
    await session.commit()
    return PostOut(
        id=str(post.id), topic_id=topic_id, author_name=profile.display_name,
        content=post.content, like_count=0, reply_count=0,
        safety_flags=post.safety_flags, created_at=post.created_at.isoformat(),
    )


# ---------------------------------------------------------------------------
# Replies
# ---------------------------------------------------------------------------


@router.get("/posts/{post_id}/replies", response_model=List[ReplyOut])
async def list_replies(
    post_id: str,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> List[ReplyOut]:
    pid = uuid.UUID(post_id)
    result = await session.execute(
        select(CommunityReplyRecord)
        .where(CommunityReplyRecord.post_id == pid, CommunityReplyRecord.is_hidden == False)
        .order_by(CommunityReplyRecord.created_at.asc())
        .limit(100)
    )
    replies = result.scalars().all()
    out: List[ReplyOut] = []
    for r in replies:
        author = await session.get(WellnessProfileRecord, r.author_id)
        out.append(ReplyOut(
            id=str(r.id), post_id=str(r.post_id),
            author_name=author.display_name if author else "Anonymous",
            content=r.content, created_at=r.created_at.isoformat(),
        ))
    return out


@router.post("/posts/{post_id}/replies", response_model=ReplyOut, status_code=status.HTTP_201_CREATED)
async def create_reply(
    post_id: str,
    body: ReplyCreate,
    user: CurrentUser = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> ReplyOut:
    profile = await _get_profile(session, user)
    scan = scan_user_input(body.content)
    reply = CommunityReplyRecord(
        post_id=uuid.UUID(post_id),
        author_id=profile.id,
        content=scan.sanitized,
        safety_flags=[scan.category.value] if not scan.passed else [],
        is_hidden=scan.category.value == "crisis",
    )
    session.add(reply)
    await log_action(
        session, action="create", resource="reply", user_id=user.user_id,
        resource_id=str(reply.id),
    )
    await session.commit()
    return ReplyOut(
        id=str(reply.id), post_id=post_id,
        author_name=profile.display_name, content=reply.content,
        created_at=reply.created_at.isoformat(),
    )
