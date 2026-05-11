# backend/app/models/food_record.py

from datetime import datetime
from typing import List, Optional
# 💡 核心特性：PostgreSQL 专属的 JSONB 
from sqlalchemy.dialects.postgresql import JSONB 
# 💡 修改点：引入 BigInteger 匹配 init.sql 中的 BIGINT
from sqlalchemy import String, Text, ForeignKey, DateTime, BigInteger, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.db.base import Base

class FoodRecord(Base):
    """
    饮食记录主表模型 (Main Food Record Entity)。
    映射数据库中的 `food_records` 表。
    """
    __tablename__ = "food_records"

    # 💡 对应 BIGSERIAL
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, index=True)
    
    # 💡 对应 BIGINT 外键
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    
    meal_type: Mapped[str] = mapped_column(String(30), nullable=False)
    record_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    source_type: Mapped[str] = mapped_column(String(30), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    
    total_calories: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    total_protein_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    total_fat_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    total_carbohydrate_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    
    raw_result_json: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default='{}')

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # 主表 -> 子表：一对多关系导航
    items: Mapped[List["FoodRecordItem"]] = relationship(
        "FoodRecordItem", back_populates="record", cascade="all, delete-orphan"
    )


class FoodRecordItem(Base):
    """
    饮食记录明细子表模型 (Food Item Detail Entity)。
    映射数据库中的 `food_record_items` 表。
    """
    __tablename__ = "food_record_items"

    # 💡 对应 BIGSERIAL
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, index=True)
    
    # 💡 对应 BIGINT 外键
    food_record_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("food_records.id", ondelete="CASCADE"), nullable=False, index=True
    )
    
    food_name: Mapped[str] = mapped_column(String(100), nullable=False)
    weight_g: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    
    calories: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    protein_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    fat_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    carbohydrate_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    
    confidence: Mapped[Optional[float]] = mapped_column(Numeric(5, 4))
    meta_json: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default='{}')

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # 子表 -> 主表：反向关联
    record: Mapped["FoodRecord"] = relationship("FoodRecord", back_populates="items")