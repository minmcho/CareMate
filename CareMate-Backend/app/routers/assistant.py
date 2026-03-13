from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from app.models.conversation import ConversationRequest, ConversationResponse
from app.services.crew_ai_service import process_message
from app.services.stt_service import transcribe_audio
from app.services.tts_service import synthesize_speech
from app.services.memory_cache import clear_history

router = APIRouter()


@router.post("/chat", response_model=ConversationResponse)
async def chat(req: ConversationRequest):
    """Main AI chat endpoint with CrewAI routing and memory caching."""
    user_text = req.message

    # If audio provided, transcribe first
    if req.audio_base64:
        stt_result = await transcribe_audio(req.audio_base64, language=req.language)
        user_text = stt_result["text"]

    if not user_text.strip():
        raise HTTPException(status_code=400, detail="Empty message")

    # Process through CrewAI
    result = await process_message(
        user_id=req.user_id,
        message=user_text,
        language=req.language,
        use_memory=req.use_memory,
    )

    # Generate TTS for reply
    reply_audio = await synthesize_speech(result["reply"], language=req.language)

    return ConversationResponse(
        reply=result["reply"],
        reply_audio_base64=reply_audio,
        agent_used=result["agent_used"],
        reasoning_steps=result.get("reasoning_steps"),
        memory_hit=result.get("memory_hit", False),
    )


@router.delete("/history/{user_id}", status_code=204)
async def clear_conversation_history(user_id: str):
    """Clear the conversation history and memory cache for a user."""
    await clear_history(user_id)


@router.get("/agents")
async def list_agents():
    """List all available AI agents."""
    return {
        "agents": [
            {"name": "Care Coordinator", "specialty": "Scheduling and daily care tasks"},
            {"name": "Medical Advisor", "specialty": "Medications and health symptoms"},
            {"name": "Diet Planner", "specialty": "Nutrition and meal planning"},
            {"name": "Medical Interpreter", "specialty": "Multilingual translation"},
            {"name": "General Assistant", "specialty": "General caregiver support"},
        ]
    }
