"""Fernet symmetric encryption for data at rest (journal entries, PII)."""

from __future__ import annotations

import base64
import os

from cryptography.fernet import Fernet

from app.core.config import get_settings


def _derive_key() -> bytes:
    """Return a Fernet-compatible key from the configured secret."""
    settings = get_settings()
    secret = settings.encryption_key
    if not secret or secret == "change-me-generate-with-fernet":
        secret = Fernet.generate_key().decode()
    raw = secret.encode()[:32].ljust(32, b"\x00")
    return base64.urlsafe_b64encode(raw)


_fernet: Fernet | None = None


def _get_fernet() -> Fernet:
    global _fernet
    if _fernet is None:
        _fernet = Fernet(_derive_key())
    return _fernet


def encrypt(plaintext: str) -> str:
    """Encrypt a string and return a URL-safe base64 token."""
    return _get_fernet().encrypt(plaintext.encode("utf-8")).decode("ascii")


def decrypt(token: str) -> str:
    """Decrypt a Fernet token back to plaintext."""
    return _get_fernet().decrypt(token.encode("ascii")).decode("utf-8")


def encrypt_preview(text: str, max_len: int = 80) -> str:
    """Encrypt a short preview of the text."""
    preview = text[:max_len].replace("\n", " ")
    if len(text) > max_len:
        preview += "…"
    return encrypt(preview)
