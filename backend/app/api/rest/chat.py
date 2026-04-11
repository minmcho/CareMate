"""REST chat endpoint — thin wrapper that enqueues the Celery task."""

from fastapi import APIRouter, Depends

from app.core.security import CurrentUser, get_current_user
from app.schemas.wellness import ChatRequest, ChatResponseDTO
from app.services.mcp import CoachMessage, MCPRouter

router = APIRouter(prefix="/chat", tags=["chat"])
_router = MCPRouter()


@router.post("/ask", response_model=ChatResponseDTO)
async def ask(
    body: ChatRequest,
    user: CurrentUser = Depends(get_current_user),
) -> ChatResponseDTO:
    history = [
        CoachMessage(role=str(m.get("role", "user")), content=str(m.get("content", "")))
        for m in body.history
    ]
    profile_ctx = f"Language: {user.language}"
    response = await _router.ask(
        user_text=body.text,
        history=history,
        profile_context=profile_ctx,
    )
    return ChatResponseDTO(
        content=response.message,
        agent=response.agent.value,
        crisis_triggered=response.crisis_triggered,
        safety_rewritten=response.safety_rewritten,
    )
