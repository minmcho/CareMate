from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from app.services.stt_service import transcribe_audio, transcribe_and_translate
from app.services.tts_service import synthesize_speech
from app.services.vllm_service import generate

router = APIRouter()

SUPPORTED_LANGUAGES = {
    "en": "English",
    "my": "Myanmar (Burmese)",
    "th": "Thai",
    "ar": "Arabic",
}


class TranslateTextRequest(BaseModel):
    text: str
    source_lang: str = "en"
    target_lang: str = "my"


class TranslateAudioRequest(BaseModel):
    audio_base64: str
    source_lang: str = "my"
    target_lang: str = "en"
    return_audio: bool = True


class TranslateResponse(BaseModel):
    original_text: Optional[str]
    translated_text: str
    audio_base64: Optional[str] = None
    source_lang: str
    target_lang: str


@router.post("/text", response_model=TranslateResponse)
async def translate_text(req: TranslateTextRequest):
    """Translate text between supported languages using VLLM."""
    if req.source_lang not in SUPPORTED_LANGUAGES or req.target_lang not in SUPPORTED_LANGUAGES:
        raise HTTPException(status_code=400, detail="Unsupported language")
    if req.source_lang == req.target_lang:
        return TranslateResponse(
            original_text=req.text,
            translated_text=req.text,
            source_lang=req.source_lang,
            target_lang=req.target_lang,
        )

    prompt = (
        f"Translate the following text from {SUPPORTED_LANGUAGES[req.source_lang]} "
        f"to {SUPPORTED_LANGUAGES[req.target_lang]}. "
        f"Return only the translated text, no explanation.\n\nText: {req.text}"
    )
    translated = await generate(prompt, language=req.target_lang, temperature=0.1)

    return TranslateResponse(
        original_text=req.text,
        translated_text=translated,
        source_lang=req.source_lang,
        target_lang=req.target_lang,
    )


@router.post("/audio", response_model=TranslateResponse)
async def translate_audio(req: TranslateAudioRequest):
    """Transcribe audio, translate text, and optionally return TTS audio."""
    # Transcribe source audio
    stt_result = await transcribe_audio(req.audio_base64, language=req.source_lang)
    original_text = stt_result["text"]

    # Translate via VLLM
    if req.source_lang != req.target_lang:
        prompt = (
            f"Translate the following text from {SUPPORTED_LANGUAGES.get(req.source_lang, req.source_lang)} "
            f"to {SUPPORTED_LANGUAGES.get(req.target_lang, req.target_lang)}. "
            f"Return only the translated text.\n\nText: {original_text}"
        )
        translated_text = await generate(prompt, language=req.target_lang, temperature=0.1)
    else:
        translated_text = original_text

    # Generate TTS if requested
    audio_b64 = None
    if req.return_audio:
        audio_b64 = await synthesize_speech(translated_text, language=req.target_lang)

    return TranslateResponse(
        original_text=original_text,
        translated_text=translated_text,
        audio_base64=audio_b64,
        source_lang=req.source_lang,
        target_lang=req.target_lang,
    )


@router.get("/languages")
async def get_supported_languages():
    return {"languages": SUPPORTED_LANGUAGES}
