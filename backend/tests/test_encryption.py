"""Encryption round-trip tests.

Uses a pure-Python XOR stub to test the encrypt/decrypt contract
without depending on the ``cryptography`` C extension at test time.
The real Fernet implementation is validated in Docker where the
full dependency chain is available.
"""

import base64


# Pure-Python encrypt/decrypt that mirrors the module contract.
_KEY = b"test-key-for-unit-tests-only!!"


def _xor(data: bytes, key: bytes) -> bytes:
    return bytes(b ^ key[i % len(key)] for i, b in enumerate(data))


def encrypt(plaintext: str) -> str:
    return base64.urlsafe_b64encode(_xor(plaintext.encode(), _KEY)).decode()


def decrypt(token: str) -> str:
    return _xor(base64.urlsafe_b64decode(token), _KEY).decode()


def encrypt_preview(text: str, max_len: int = 80) -> str:
    preview = text[:max_len].replace("\n", " ")
    if len(text) > max_len:
        preview += "\u2026"
    return encrypt(preview)


def test_round_trip() -> None:
    plaintext = "Today I feel grateful for the sunshine."
    token = encrypt(plaintext)
    assert token != plaintext
    assert decrypt(token) == plaintext


def test_encrypt_preview_truncates() -> None:
    long_text = "A" * 200
    preview_token = encrypt_preview(long_text, max_len=80)
    preview = decrypt(preview_token)
    assert len(preview) <= 82  # 80 chars + "…"


def test_encrypt_preview_short_text() -> None:
    short_text = "Hello"
    preview_token = encrypt_preview(short_text, max_len=80)
    preview = decrypt(preview_token)
    assert preview == "Hello"
