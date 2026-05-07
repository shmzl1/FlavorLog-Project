# backend/app/models/health_feedback.py

from datetime import datetime
from typing import Optional
from sqlalchemy import String, Text, ForeignKey, DateTime, BigInteger, Integer
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.db.base import Base

class HealthFeedback(Base):
    """
    健康反馈记录模型。
    用于记录用户餐后的身体感受。
    """
    __tablename__ = "health_feedbacks"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # 可选：关联某一次具体的饮食记录
    food_record_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("food_records.id", ondelete="SET NULL"), nullable=True)
    
    # 💡 核心修复：将 server_default 改为 default
    # 这样 SQLAlchemy 会在 Python 层面自动生成当前时间并发送给数据库，解决 NotNullViolation 错误
    feedback_time: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        nullable=False, 
        default=func.now() 
    )
    
    # 核心感受指标 (0-10分)
    bloating_level: Mapped[int] = mapped_column(Integer, default=0) # 腹胀感
    fatigue_level: Mapped[int] = mapped_column(Integer, default=0)  # 疲劳感
    
    mood: Mapped[Optional[str]] = mapped_column(String(50)) # 心情：happy, neutral, low
    digestive_note: Mapped[Optional[str]] = mapped_column(Text) # 详细备注
    extra_symptoms: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default='[]') # 其他症状列表

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())