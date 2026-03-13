from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum


class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in-progress"
    COMPLETED = "completed"


class ScheduleTaskCreate(BaseModel):
    title_en: str
    title_my: str
    time: str  # "HH:MM"
    status: TaskStatus = TaskStatus.PENDING
    user_id: str


class ScheduleTaskUpdate(BaseModel):
    title_en: Optional[str] = None
    title_my: Optional[str] = None
    time: Optional[str] = None
    status: Optional[TaskStatus] = None


class ScheduleTaskOut(BaseModel):
    id: str
    title_en: str
    title_my: str
    time: str
    status: TaskStatus
    user_id: str
    created_at: datetime
    updated_at: datetime
