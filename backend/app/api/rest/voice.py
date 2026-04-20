"""Voice-to-text processing endpoints for journaling and community posting."""

from fastapi import APIRouter, Depends

from app.core.security import CurrentUser, get_current_user
from app.schemas.wellness import VoiceTranscribeRequest, VoiceTranscribeResponse
from app.services.reasoning_context import ReasoningContextStore
from app.services.safety import scan_user_input

router = APIRouter(prefix="/voice", tags=["voice"])


@router.post("/transcribe", response_model=VoiceTranscribeResponse)
async def transcribe(
    body: VoiceTranscribeRequest,
    user: CurrentUser = Depends(get_current_user),
) -> VoiceTranscribeResponse:
    scan = scan_user_input(body.transcript)
    store = ReasoningContextStore()
    store.append_event(
        user.user_id,
        "voice_transcription",
        {
            "source": body.source,
            "safety_category": scan.category.value,
            "length": len(scan.sanitized),
        },
    )
    return VoiceTranscribeResponse(
        transcript=body.transcript,
        sanitized_transcript=scan.sanitized,
        source=body.source,
        safety_category=scan.category.value,
    )
