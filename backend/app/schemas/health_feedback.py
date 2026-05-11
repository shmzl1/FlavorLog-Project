# backend/app/schemas/health_feedback.py

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List

class HealthFeedbackBase(BaseModel):
    bloating_level: int = Field(0, ge=0, le=10)
    fatigue_level: int = Field(0, ge=0, le=10)
    mood: Optional[str] = None
    digestive_note: Optional[str] = None
    extra_symptoms: List[str] = []
    food_record_id: Optional[int] = None

class HealthFeedbackCreate(HealthFeedbackBase):
    pass

class HealthFeedbackResponse(HealthFeedbackBase):
    id: int
    user_id: int
    feedback_time: datetime

    class Config:
        from_attributes = True