# backend/app/schemas/fridge.py

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class FridgeItemBase(BaseModel):
    """冰箱食材基础属性"""
    name: str = Field(..., description="食材名称，如：西红柿")
    category: Optional[str] = Field("其他", description="分类：蔬菜、肉类、水果等")
    quantity: float = Field(1.0, description="数量")
    unit: str = Field("个", description="单位：个、克、毫升等")
    expiration_date: Optional[datetime] = Field(None, description="过期时间")

class FridgeItemCreate(FridgeItemBase):
    """添加食材时的请求体 (完全继承基础属性)"""
    pass

class FridgeItemUpdate(BaseModel):
    """
    修改食材时的请求体。
    所有字段都是可选的，前端传了哪个字段，我们就只更新哪个字段。
    """
    name: Optional[str] = None
    category: Optional[str] = None
    quantity: Optional[float] = None
    unit: Optional[str] = None
    expiration_date: Optional[datetime] = None

class FridgeItemResponse(FridgeItemBase):
    """返回给前端的食材格式"""
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True