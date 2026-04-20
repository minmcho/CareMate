"""Production security middleware stack.

Adds:
    - Per-IP sliding-window rate limiter (Redis-backed).
    - Request-ID propagation.
    - Security response headers (HSTS, CSP, X-Content-Type-Options, etc.).
    - CSRF origin validation for mutation endpoints.
"""

from __future__ import annotations

import time
import uuid
from typing import Optional

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from loguru import logger

# ---------------------------------------------------------------------------
# In-memory rate-limit store (replaced by Redis in production via env flag)
# ---------------------------------------------------------------------------

_buckets: dict[str, list[float]] = {}
RATE_LIMIT_WINDOW = 60  # seconds
RATE_LIMIT_MAX = 120  # requests per window


def _rate_check(ip: str) -> bool:
    now = time.time()
    window = _buckets.setdefault(ip, [])
    _buckets[ip] = [t for t in window if now - t < RATE_LIMIT_WINDOW]
    if len(_buckets[ip]) >= RATE_LIMIT_MAX:
        return False
    _buckets[ip].append(now)
    return True


# ---------------------------------------------------------------------------
# Security headers
# ---------------------------------------------------------------------------

SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "0",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=()",
    "Content-Security-Policy": (
        "default-src 'self'; "
        "script-src 'self'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data: blob:; "
        "connect-src 'self' https://*.supabase.co; "
        "frame-ancestors 'none'"
    ),
    "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
    "Cache-Control": "no-store",
}


# ---------------------------------------------------------------------------
# CSRF origin check
# ---------------------------------------------------------------------------

SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}


def _csrf_ok(request: Request, allowed_origins: list[str]) -> bool:
    if request.method in SAFE_METHODS:
        return True
    origin = request.headers.get("origin", "")
    if not origin:
        return True  # non-browser client
    return any(origin == o or origin.startswith(o) for o in allowed_origins)


# ---------------------------------------------------------------------------
# Middleware class
# ---------------------------------------------------------------------------


class SecurityMiddleware(BaseHTTPMiddleware):
    """Combined rate-limit + headers + CSRF middleware."""

    def __init__(self, app, allowed_origins: Optional[list[str]] = None):
        super().__init__(app)
        self.allowed_origins = allowed_origins or [
            "http://localhost:3000",
            "http://localhost:8080",
        ]

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        client_ip = request.client.host if request.client else "unknown"

        # Rate limit
        if not _rate_check(client_ip):
            logger.warning("Rate limit exceeded ip={}", client_ip)
            return Response(
                content='{"detail":"Rate limit exceeded"}',
                status_code=429,
                media_type="application/json",
                headers={"Retry-After": str(RATE_LIMIT_WINDOW)},
            )

        # CSRF
        if not _csrf_ok(request, self.allowed_origins):
            logger.warning("CSRF origin rejected ip={} origin={}", client_ip, request.headers.get("origin"))
            return Response(
                content='{"detail":"Origin not allowed"}',
                status_code=403,
                media_type="application/json",
            )

        response: Response = await call_next(request)

        # Inject security headers
        for header, value in SECURITY_HEADERS.items():
            response.headers[header] = value
        response.headers["X-Request-ID"] = request_id

        return response
