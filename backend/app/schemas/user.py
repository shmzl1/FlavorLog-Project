# backend/app/schemas/user.py

from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
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

class UserResponse(UserBase):
    """
    返回给前端的用户信息展示 Schema。

    作用：
    定义后端向前端返回用户数据时的结构。
    💡 关键修改：同步了个人资料相关的字段，确保在 API 返回中能看到这些信息。
    """
    id: int
    created_at: datetime
    
    # 💡 新增：使返回的数据包含详细的个人资料
    nickname: Optional[str] = None
    gender: Optional[str] = "unknown"
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    health_goal: Optional[str] = None
    
    # 支持返回饮食偏好和过敏源列表
    diet_preference: List[str] = []
    allergens: List[str] = []
    
    class Config:
        """
        Pydantic 内部配置类。
        作用：开启 `from_attributes = True`，允许直接读取 SQLAlchemy ORM 对象。
        """
        from_attributes = True

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