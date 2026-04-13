"""Safety integration tests for community content."""

from app.services.safety import SafetyCategory, scan_user_input


def test_community_post_crisis_detected() -> None:
    result = scan_user_input("I want to hurt myself and nobody cares.")
    assert result.passed is False
    assert result.category == SafetyCategory.CRISIS


def test_community_post_pii_redacted() -> None:
    result = scan_user_input("My email is user@test.com, call me at 12345678901.")
    assert result.category == SafetyCategory.PII
    assert "user@test.com" not in result.sanitized
    assert "12345678901" not in result.sanitized


def test_community_post_clean() -> None:
    result = scan_user_input("Mindful breathing helped me sleep better this week!")
    assert result.passed is True
    assert result.category == SafetyCategory.OK
