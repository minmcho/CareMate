from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum


class MealType(str, Enum):
    BREAKFAST = "breakfast"
    LUNCH = "lunch"
    DINNER = "dinner"
    SNACK = "snack"


class MealCreate(BaseModel):
    type: MealType
    title: str
    time: str
    user_id: str


class RecipeCreate(BaseModel):
    title: str
    cooking_time: str
    ingredients_en: List[str]
    ingredients_my: List[str]
    instructions_en: List[str]
    instructions_my: List[str]
    image_url: Optional[str] = None
    user_id: str


class RecipeOut(BaseModel):
    id: str
    title: str
    cooking_time: str
    ingredients_en: List[str]
    ingredients_my: List[str]
    instructions_en: List[str]
    instructions_my: List[str]
    image_url: Optional[str]
    user_id: str
    created_at: datetime


class RecipeExtractRequest(BaseModel):
    image_base64: str  # Base64-encoded image
    user_id: str
