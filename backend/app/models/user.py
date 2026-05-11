# backend/app/models/user.py

from typing import List, Optional
from datetime import date, datetime
from sqlalchemy import String, Numeric, Date, DateTime, Boolean, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.db.base import Base

class User(Base):
    """
    用户深度画像模型。
    
    作用：
    映射 `users` 表[cite: 2]。除了基础的鉴权信息，它还承载了用户的生物学特征（身高、体重）
    以及饮食偏好[cite: 2]。这些数据在后续调用 LLM 生成个性化菜谱推荐时，
    将作为关键的上下文（Context）输入给大模型。
    """
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True, nullable=False)
    email: Mapped[str] = mapped_column(String(120), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    
    # 扩展资料
    nickname: Mapped[Optional[str]] = mapped_column(String(50))
    avatar_url: Mapped[Optional[str]] = mapped_column(Text)
    gender: Mapped[str] = mapped_column(String(20), default="unknown")
    birth_date: Mapped[Optional[date]] = mapped_column(Date)
    
    # 身体指标：用于精准计算卡路里需求
    height_cm: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    weight_kg: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    
    # 个性化 AI 推荐的核心权重字段
    health_goal: Mapped[Optional[str]] = mapped_column(String(50)) # 例如: 减脂、增肌
    diet_preference: Mapped[list] = mapped_column(JSONB, default=list, server_default='[]', nullable=False) # 饮食偏好
    allergens: Mapped[list] = mapped_column(JSONB, default=list, server_default='[]', nullable=False) # 过敏原[cite: 2]
    profile_json: Mapped[dict] = mapped_column(JSONB, default=dict, server_default='{}', nullable=False)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
