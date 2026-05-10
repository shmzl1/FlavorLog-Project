# backend/app/schemas/food_record.py

from pydantic import BaseModel, ConfigDict, Field
from datetime import datetime
from typing import List, Optional, Dict, Any

# ==========================================
# 1. FoodRecordItem (食物明细子表) 的 Schema
# ==========================================

class FoodRecordItemBase(BaseModel):
    food_name: str
    weight_g: Optional[float] = None
    calories: Optional[float] = None
    protein_g: Optional[float] = None
    fat_g: Optional[float] = None
    carbohydrate_g: Optional[float] = None
    confidence: Optional[float] = None
    meta_json: Optional[Dict[str, Any]] = None

class FoodRecordItemCreate(FoodRecordItemBase):
    """创建明细时的入参格式"""
    pass

class FoodRecordItem(FoodRecordItemBase):
    """从数据库查询出来的明细格式"""
    id: int
    # 💡 修复点：这里必须和 models 里定义的外键字段名完全一致！
    food_record_id: int

    # Pydantic V2 写法：允许从 SQLAlchemy 的 ORM 模型直接转化
    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 2. FoodRecord (饮食记录主表) 的 Schema
# ==========================================

class FoodRecordBase(BaseModel):
    meal_type: str = "snack"
    # 💡 修复点：给时间加上默认工厂函数，防止触发数据库的非空约束报错
    record_time: datetime = Field(default_factory=datetime.now)
    source_type: str = "manual"  # manual, photo_ai, video_ai 等
    description: Optional[str] = None
    
    total_calories: Optional[float] = None
    total_protein_g: Optional[float] = None
    total_fat_g: Optional[float] = None
    total_carbohydrate_g: Optional[float] = None
    
    raw_result_json: Optional[Dict[str, Any]] = None

class FoodRecordCreate(FoodRecordBase):
    """
    【增】创建/极速录入草稿 时的入参格式
    包含了一个 items 列表，用于一次性接收多个食物明细
    """
    items: List[FoodRecordItemCreate] = []

class FoodRecordUpdate(BaseModel):
    """
    【改】修改记录时的入参格式
    所有字段都是 Optional 的，前端传了哪个就改哪个
    """
    meal_type: Optional[str] = None
    description: Optional[str] = None
    record_time: Optional[datetime] = None

class FoodRecord(FoodRecordBase):
    """【查】从数据库查询出来的完整记录格式 (基础实体)"""
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime
    
    # 嵌套包含查询出来的子表明细
    items: List[FoodRecordItem] = []

    model_config = ConfigDict(from_attributes=True)


# ==========================================
# 3. API 路由专属依赖 (对齐 api/v1/food_records.py)
# ==========================================

class FoodRecordResponse(FoodRecord):
    """
    专门用于给前端返回的响应体模型。
    继承自 FoodRecord，如果以后前端需要额外补充字段，加在这里即可，不污染底层的 FoodRecord。
    """
    pass

class PhotoRecognitionRequest(BaseModel):
    """
    图片识别 Mock 接口的入参格式
    """
    image_url: Optional[str] = None
    image_base64: Optional[str] = None
    # 可以根据你前端实际传参的情况在这里加字段