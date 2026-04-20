"""Speech-to-Text service using OpenAI Whisper (via transformers or faster-whisper)."""
import base64
import io
import tempfile
import os
from typing import Optional

import torch
from faster_whisper import WhisperModel

from app.config import settings


_model: Optional[WhisperModel] = None


def get_stt_model() -> WhisperModel:
    global _model
    if _model is None:
        device = settings.STT_DEVICE if torch.cuda.is_available() else "cpu"
        compute_type = "float16" if device == "cuda" else "int8"
        _model = WhisperModel(
            "large-v3",
            device=device,
            compute_type=compute_type,
        )
        print(f"Whisper model loaded on {device}")
    return _model


def detect_language_code(lang: str) -> str:
    """Map app language code to Whisper language code."""
    mapping = {
        "en": "en",
        "my": "my",   # Myanmar/Burmese
        "th": "th",   # Thai
        "ar": "ar",   # Arabic
    }
    return mapping.get(lang, "en")


async def transcribe_audio(audio_base64: str, language: str = "en") -> dict:
    """
    Transcribe base64-encoded audio (WAV/MP3/M4A) to text.
    Returns: {"text": str, "language": str, "confidence": float}
    """
    model = get_stt_model()
    audio_bytes = base64.b64decode(audio_base64)
    lang_code = detect_language_code(language)

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        segments, info = model.transcribe(
            tmp_path,
            language=lang_code if lang_code != "en" else None,
            beam_size=5,
            vad_filter=True,
        )
        text = " ".join(seg.text.strip() for seg in segments)
        return {
            "text": text,
            "language": info.language,
            "confidence": float(info.language_probability),
        }
    finally:
        os.unlink(tmp_path)


async def transcribe_and_translate(audio_base64: str, target_language: str = "en") -> dict:
    """
    Transcribe audio and translate to target language using Whisper's translation task.
    Always translates into English; for other targets, pass through VLLM afterward.
    """
    model = get_stt_model()
    audio_bytes = base64.b64decode(audio_base64)

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = tmp.name

    try:
        segments, info = model.transcribe(
            tmp_path,
            task="translate",  # Whisper translate task → English
            beam_size=5,
            vad_filter=True,
        )
        translated_text = " ".join(seg.text.strip() for seg in segments)
        return {
            "original_language": info.language,
            "translated_text": translated_text,
        }
    finally:
        os.unlink(tmp_path)
