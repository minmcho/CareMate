"""Text-to-Speech service using Coqui TTS or edge-tts for multilingual output."""
import base64
import io
import tempfile
import os
from typing import Optional

import edge_tts

# Voice mappings per language
VOICE_MAP = {
    "en": "en-US-JennyNeural",
    "my": "my-MM-NilarNeural",
    "th": "th-TH-PremwadeeNeural",
    "ar": "ar-SA-ZariyahNeural",
}


async def synthesize_speech(text: str, language: str = "en") -> str:
    """
    Convert text to speech and return base64-encoded MP3 audio.
    Uses Microsoft Edge TTS (edge-tts) for multilingual support.
    """
    voice = VOICE_MAP.get(language, VOICE_MAP["en"])

    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        communicate = edge_tts.Communicate(text, voice)
        await communicate.save(tmp_path)
        with open(tmp_path, "rb") as f:
            audio_bytes = f.read()
        return base64.b64encode(audio_bytes).decode("utf-8")
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


async def list_available_voices() -> list:
    """Return list of all available TTS voices."""
    voices = await edge_tts.list_voices()
    return [
        {
            "name": v["Name"],
            "language": v["Locale"],
            "gender": v["Gender"],
        }
        for v in voices
    ]
