# backend/app/schemas/food_record.py

from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime

# ==========================================
# 1. 子表 (食物明细) 的契约
# ==========================================
class FoodRecordItemBase(BaseModel):
    food_name: str = Field(..., description="食物名称，如：米饭")
    weight_g: Optional[float] = Field(None, description="重量(克)")
    calories: Optional[float] = 0.0
    protein_g: Optional[float] = 0.0
    fat_g: Optional[float] = 0.0
    carbohydrate_g: Optional[float] = 0.0
    confidence: Optional[float] = Field(None, description="AI识别置信度")
    meta_json: Optional[Dict[str, Any]] = Field(default_factory=dict, description="AI识别边界框等元数据")

class FoodRecordItemCreate(FoodRecordItemBase):
    pass

class FoodRecordItemResponse(FoodRecordItemBase):
    id: int
    food_record_id: int

    class Config:
        from_attributes = True

# ==========================================
# 2. 主表 (饮食记录) 的契约
# ==========================================
class FoodRecordBase(BaseModel):
    meal_type: str = Field(..., description="餐别：breakfast, lunch, dinner, snack")
    record_time: datetime = Field(..., description="用餐的具体时间")
    source_type: str = Field("manual", description="来源：manual 或 ai_vision")
    description: Optional[str] = Field(None, description="备注")
    total_calories: Optional[float] = 0.0
    total_protein_g: Optional[float] = 0.0
    total_fat_g: Optional[float] = 0.0
    total_carbohydrate_g: Optional[float] = 0.0
    raw_result_json: Optional[Dict[str, Any]] = Field(default_factory=dict)

class FoodRecordCreate(FoodRecordBase):
    """
    💡 核心：这里定义了一个 items 列表！
    告诉前端：创建记录时，必须带上这一餐包含了哪些食物。
    """
    items: List[FoodRecordItemCreate] = Field(default_factory=list, description="这顿饭包含的具体食物列表")

class FoodRecordUpdate(BaseModel):
    meal_type: Optional[str] = None
    record_time: Optional[datetime] = None
    description: Optional[str] = None

class FoodRecordResponse(FoodRecordBase):
    """返回给前端时，也会把子表的数据一并带出去"""
    id: int
    user_id: int
    created_at: datetime
    
    # 💡 核心：返回的数据中包含明细列表
    items: List[FoodRecordItemResponse] = []

    class Config:
        from_attributes = True