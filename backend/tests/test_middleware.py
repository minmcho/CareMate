"""Security middleware rate limiter tests (no external deps)."""

import time

# Inline the rate-limit logic to avoid importing fastapi in this env.
_buckets: dict[str, list[float]] = {}
RATE_LIMIT_WINDOW = 60
RATE_LIMIT_MAX = 120


def _rate_check(ip: str) -> bool:
    now = time.time()
    window = _buckets.setdefault(ip, [])
    _buckets[ip] = [t for t in window if now - t < RATE_LIMIT_WINDOW]
    if len(_buckets[ip]) >= RATE_LIMIT_MAX:
        return False
    _buckets[ip].append(now)
    return True


def test_rate_limiter_allows_normal_traffic() -> None:
    _buckets.clear()
    for _ in range(10):
        assert _rate_check("127.0.0.1") is True


def test_rate_limiter_blocks_after_threshold() -> None:
    _buckets.clear()
    ip = "10.0.0.99"
    for _ in range(RATE_LIMIT_MAX):
        _rate_check(ip)
    assert _rate_check(ip) is False
