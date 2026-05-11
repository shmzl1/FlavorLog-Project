from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class RecipeRecommendationResponse(BaseModel):
    id: int
    user_id: int
    task_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    recipe_type: Optional[str] = None
    ingredients_json: List[Any] = Field(default_factory=list)
    steps_json: List[Any] = Field(default_factory=list)
    nutrition_json: Dict[str, Any] = Field(default_factory=dict)
    score: Optional[float] = None
    reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
