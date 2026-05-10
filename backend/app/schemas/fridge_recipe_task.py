from typing import List, Literal, Optional
from pydantic import BaseModel, Field


class FridgeRecipeTaskRequest(BaseModel):
    target: str = Field(..., description="目标：high_protein / lose_fat / healthy 等")
    avoid_ingredients: List[str] = []
    preferred_cuisine: Optional[str] = Field(default=None, description="偏好菜系：chinese 等")
    max_calories: Optional[int] = Field(default=None, ge=0)
    use_expiring_first: bool = True


class RecipeIngredient(BaseModel):
    name: str
    amount: str


class RecipeNutrition(BaseModel):
    calories: int
    protein_g: float
    fat_g: float
    carbohydrate_g: float


class FridgeRecipeTaskSubmitData(BaseModel):
    task_id: str
    status: Literal["pending", "running", "success", "failed"] = "pending"
    message: str = "食谱生成任务已提交"


class FridgeRecipeTaskResult(BaseModel):
    recipe_id: int
    title: str
    description: Optional[str] = None
    ingredients: List[RecipeIngredient]
    steps: List[str]
    nutrition: RecipeNutrition
    score: float


class FridgeRecipeTaskResultData(BaseModel):
    task_id: str
    status: Literal["pending", "running", "success", "failed"]
    result: Optional[FridgeRecipeTaskResult] = None
