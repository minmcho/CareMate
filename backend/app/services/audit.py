"""Immutable audit logging for security-sensitive actions."""

from __future__ import annotations

from typing import Optional

from loguru import logger
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.wellness import AuditLogRecord


async def log_action(
    session: AsyncSession,
    *,
    action: str,
    resource: str,
    user_id: Optional[str] = None,
    resource_id: Optional[str] = None,
    ip_address: Optional[str] = None,
    user_agent: Optional[str] = None,
    details: Optional[dict] = None,
) -> None:
    """Insert an immutable audit row. Failures are logged but never raise."""
    try:
        record = AuditLogRecord(
            user_id=user_id,
            action=action,
            resource=resource,
            resource_id=resource_id,
            ip_address=ip_address,
            user_agent=user_agent,
            details=details or {},
        )
        session.add(record)
        await session.flush()
    except Exception as exc:
        logger.warning("Audit log write failed: {}", exc)
