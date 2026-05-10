from typing import List, Literal, Optional
from pydantic import BaseModel, Field


GoalType = Literal["lose_fat", "gain_muscle", "maintain", "healthy"]
BudgetLevel = Literal["low", "medium", "high"]
MealType = Literal["breakfast", "lunch", "dinner", "snack"]


class Nutrition(BaseModel):
    calories: int = Field(..., ge=0)
    protein_g: float = Field(..., ge=0)
    fat_g: float = Field(..., ge=0)
    carbohydrate_g: float = Field(..., ge=0)


class RecipeRecommendationItem(BaseModel):
    title: str
    reason: str
    nutrition: Nutrition
    score: float = Field(..., ge=0, le=1)


class RecommendationRecipeRequest(BaseModel):
    goal: GoalType
    budget_level: BudgetLevel = "medium"
    meal_type: MealType
    avoid_ingredients: List[str] = []
    preferred_ingredients: List[str] = []
    max_calories: Optional[int] = Field(default=None, ge=0)


class RecommendationTaskSubmitData(BaseModel):
    task_id: str
    status: Literal["pending", "running", "success", "failed"] = "pending"
    message: str = "推荐任务已提交"


class RecommendationTaskResultData(BaseModel):
    task_id: str
    status: Literal["pending", "running", "success", "failed"]
    result: Optional[dict] = None


class MenuScanRequest(BaseModel):
    file_id: int
    health_goal: GoalType
    avoid_ingredients: List[str] = []


class MenuScanItem(BaseModel):
    name: str
    level: Literal["red", "yellow", "green"]
    reason: str


class MenuScanResultData(BaseModel):
    menu_items: List[MenuScanItem]
    best_choice: str
