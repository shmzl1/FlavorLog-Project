# backend/app/schemas/user.py

import re
from pydantic import BaseModel, EmailStr, Field, ConfigDict, model_validator
from datetime import date, datetime
from typing import Optional, List

# 11位中国大陆手机号正则
_PHONE_RE = re.compile(r'^1[3-9]\d{9}$')

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

class UserCreate(BaseModel):
    """
    接收前端注册/创建用户请求的 Schema。
    支持邮箱注册或11位中国大陆手机号注册（二选一，手机号注册时 email 可省略）。
    """
    username: str
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    password: str
    nickname: Optional[str] = None
    is_active: Optional[bool] = True

    @model_validator(mode='after')
    def check_email_or_phone(self) -> 'UserCreate':
        if not self.email and not self.phone:
            raise ValueError('邮箱和手机号至少填写一项')
        if self.phone and not _PHONE_RE.match(self.phone):
            raise ValueError('手机号格式不正确，请输入11位中国大陆手机号')
        return self

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

    phone: Optional[str] = None

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
    
    phone: Optional[str] = None
    email: Optional[EmailStr] = None

    class Config:
        from_attributes = True


class UserStatsResponse(BaseModel):
    checkin_days: int
    food_record_count: int
    award_count: int
    weekly_record_count: int
    streak_days: int
