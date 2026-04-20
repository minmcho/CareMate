"""Voice transcription route and schema smoke tests."""

import importlib.util

import pytest


if importlib.util.find_spec("fastapi") is None:
    pytestmark = pytest.mark.skip(reason="fastapi is not installed in this test environment")


def test_voice_transcribe_route_is_registered() -> None:
    from app.main import create_app

    app = create_app()
    paths = {route.path for route in app.routes}
    assert "/voice/transcribe" in paths
