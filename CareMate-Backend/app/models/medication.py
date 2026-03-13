from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class MedicationCreate(BaseModel):
    name_en: str
    name_my: str
    dosage: str
    time: str  # "HH:MM"
    notes: Optional[str] = None
    user_id: str


class MedicationUpdate(BaseModel):
    name_en: Optional[str] = None
    name_my: Optional[str] = None
    dosage: Optional[str] = None
    time: Optional[str] = None
    taken: Optional[bool] = None
    notes: Optional[str] = None


class MedicationOut(BaseModel):
    id: str
    name_en: str
    name_my: str
    dosage: str
    time: str
    taken: bool
    notes: Optional[str]
    user_id: str
    created_at: datetime
