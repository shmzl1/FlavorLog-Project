# backend/app/models/health.py

from datetime import datetime
from typing import Optional
# 💡 核心修复：必须从 postgresql 方言包导入 JSONB 才能被 Pylance 识别
from sqlalchemy.dialects.postgresql import JSONB 
from sqlalchemy import String, Text, ForeignKey, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.db.base import Base

class HealthFeedback(Base):
    """
    用户餐后健康反馈模型 (Health Feedback Entity)。
    
    架构作用：
    映射数据库中的 `health_feedbacks` 表。
    本模型用于收集并数字化用户在进食后的生物学反应（如消化情况、能量水平、情绪状态）。
    
    数据价值：
    作为“标签数据”，这些反馈是系统中 AI 推荐算法实现“闭环学习”的关键。
    算法层会关联 FoodRecord 与此表，通过机器学习识别导致用户不适的潜在过敏原或饮食诱因，
    从而在未来的赛博冰箱推荐中实现更高精度的规避。
    """
    __tablename__ = "health_feedbacks"

    # 基础主键与外键关联
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # 强制关联用户，支持级联删除
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    
    # 可选关联某次具体的饮食记录[cite: 2]
    # 若饮食记录被删除，反馈保留（SET NULL），用于长期的健康趋势分析
    food_record_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("food_records.id", ondelete="SET NULL"), nullable=True, index=True
    )

    # 核心反馈指标
    feedback_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    
    # 采用 0-5 级评分制，0 表示无感
    bloating_level: Mapped[int] = mapped_column(Integer, default=0, server_default='0') # 腹胀感
    fatigue_level: Mapped[int] = mapped_column(Integer, default=0, server_default='0')  # 疲劳感/饭困
    
    mood: Mapped[Optional[str]] = mapped_column(String(50)) # 进食后的情绪
    digestive_note: Mapped[Optional[str]] = mapped_column(Text) # 具体的消化情况备注描述
    
    # 扩展症状列表：例如 ["头痛", "皮肤发红"]
    # 存储为 JSONB 格式以支持 PostgreSQL 的高效路径查询
    extra_symptoms: Mapped[list] = mapped_column(JSONB, nullable=False, server_default='[]')

    # 系统审计时间戳[cite: 2]
    # 💡 核心修复：Mapped 括号里写 Python 类型，func.now() 放在右边作为数据库默认值
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    def __repr__(self) -> str:
        """
        对象的开发者友好字符串表示。
        """
        return f"<HealthFeedback(user_id={self.user_id}, mood={self.mood})>"