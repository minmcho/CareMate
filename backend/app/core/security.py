"""JWT verification and request context helpers (Supabase-compatible)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from fastapi import Header, HTTPException, status
from jose import JWTError, jwt

from app.core.config import get_settings


@dataclass
class CurrentUser:
    user_id: str
    email: Optional[str]
    language: str = "en"


async def get_current_user(authorization: str | None = Header(default=None)) -> CurrentUser:
    """Decode a Supabase JWT and return the current user context.

    The token is expected on every GraphQL / REST call. Crisis and safety
    audit logs are written against ``user_id`` — not the raw token — so we
    can safely discard the token immediately after decoding.
    """
    settings = get_settings()
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    token = authorization.split(" ", 1)[1]
    try:
        payload = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
    except JWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        ) from exc

    sub = payload.get("sub")
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject",
        )

    return CurrentUser(
        user_id=str(sub),
        email=payload.get("email"),
        language=str(payload.get("user_metadata", {}).get("lang", "en")),
    )
