from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class FoodBlacklistItem(BaseModel):
    food_name: str
    reason: str
    support: float = Field(ge=0, le=1)
    confidence: float = Field(ge=0, le=1)
    suggestion: str


class FoodRedItem(BaseModel):
    food_name: str
    reason: str
    score: float = Field(ge=0, le=1)


class FoodBlacklistResponse(BaseModel):
    black_items: List[FoodBlacklistItem]
    red_items: List[FoodRedItem]
    generated_at: datetime


class CalorieTrendItem(BaseModel):
    date: date
    calories: float


class WeeklyReportResponse(BaseModel):
    week_start: date
    week_end: date
    avg_calories: float
    avg_protein_g: float
    calorie_trend: List[CalorieTrendItem]
    warnings: List[str]
    suggestions: List[str]


class TasteVectorResponse(BaseModel):
    user_id: int
    vector: List[float]
    tags: List[str]
    updated_source: Optional[str] = None
