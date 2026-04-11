"""Safety validator regression tests."""

from app.services.safety import (
    SafetyCategory,
    hash_for_audit,
    scan_assistant_output,
    scan_user_input,
)


def test_scan_user_input_clean() -> None:
    result = scan_user_input("I feel stressed about work today.")
    assert result.passed is True
    assert result.category == SafetyCategory.OK


def test_scan_user_input_crisis() -> None:
    result = scan_user_input("I want to hurt myself.")
    assert result.passed is False
    assert result.category == SafetyCategory.CRISIS
    assert result.sanitized == "[redacted]"


def test_scan_user_input_pii_redacted() -> None:
    result = scan_user_input("Email me at alex@example.com.")
    assert result.passed is True
    assert result.category == SafetyCategory.PII
    assert "alex@example.com" not in result.sanitized


def test_scan_assistant_output_rewrites_medical_claims() -> None:
    result = scan_assistant_output("This will cure your diabetes.")
    assert result.passed is False
    assert result.category == SafetyCategory.MEDICAL_CLAIM
    assert "cure" not in result.sanitized.lower()
    assert "wellness" in result.sanitized.lower()


def test_scan_assistant_output_passes_safe_text() -> None:
    result = scan_assistant_output("A short walk can lift your mood.")
    assert result.passed is True


def test_hash_for_audit_stable() -> None:
    assert hash_for_audit("hello") == hash_for_audit("hello")
