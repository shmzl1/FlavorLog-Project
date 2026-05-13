# backend/app/schemas/user.py

from pydantic import BaseModel, EmailStr, Field,ConfigDict
from datetime import date, datetime
from typing import Optional, List

class UserBase(BaseModel):
    """
    用户数据的基础 Schema。

    作用：
    提取用户数据中各个场景都会用到的公共字段（如邮箱、用户名）。
    作为父类被其他请求或响应模型继承，能够有效避免代码冗余。
    这里使用了 Pydantic 提供的 EmailStr 来强制校验邮箱格式的合法性。
    """
    username: str
    email: EmailStr
    is_active: Optional[bool] = True

class UserCreate(UserBase):
    """
    接收前端注册/创建用户请求的 Schema。

    作用：
    严格定义前端在注册新用户时必须提交的 JSON 数据结构。
    相比于基础模型，这里额外增加了 `password` 字段。
    我们特意将其与响应模型分离，确保密码只在接收时有效，绝不会被意外暴露给外部。
    """
    password: str
    nickname: Optional[str] = None

class UserResponse(UserBase):
    """
    返回给前端的用户信息展示 Schema。
    """
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    gender: Optional[str] = "unknown"
    birth_date: Optional[date] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    health_goal: Optional[str] = None

    diet_preference: List[str] = Field(default_factory=list)
    allergens: List[str] = Field(default_factory=list)

class UserUpdate(BaseModel):
    """
    用户资料更新契约。
    所有字段均为可选，前端传哪个，我们就改哪个。
    """
    nickname: Optional[str] = Field(None, max_length=50)
    gender: Optional[str] = Field(None, description="unknown, male, female")
    height_cm: Optional[float] = Field(None, ge=0, le=300)
    weight_kg: Optional[float] = Field(None, ge=0, le=500)
    health_goal: Optional[str] = Field(None, description="lose_weight, keep_fit, gain_muscle")
    
    # 允许修改饮食偏好和过敏源 (对应数据库中的 JSONB)
    diet_preference: Optional[List[str]] = None
    allergens: Optional[List[str]] = None

    class Config:
        from_attributes = True
