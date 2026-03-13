from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class MessageRole(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class Message(BaseModel):
    role: MessageRole
    content: str
    timestamp: datetime


class ConversationRequest(BaseModel):
    user_id: str
    message: str
    language: str = "en"   # en, my, th, ar
    audio_base64: Optional[str] = None  # for voice input
    use_memory: bool = True


class ConversationResponse(BaseModel):
    reply: str
    reply_audio_base64: Optional[str] = None
    agent_used: str
    reasoning_steps: Optional[List[str]] = None
    memory_hit: bool = False


class ConversationHistory(BaseModel):
    id: str
    user_id: str
    messages: List[Message]
    created_at: datetime
    updated_at: datetime
