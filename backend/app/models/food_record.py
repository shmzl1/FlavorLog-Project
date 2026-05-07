# backend/app/models/food_record.py

from datetime import datetime
from typing import List, Optional
# 💡 核心修复：必须从 postgresql 方言包导入 JSONB 才能支持高级 JSON 特性
from sqlalchemy.dialects.postgresql import JSONB 
from sqlalchemy import String, Text, ForeignKey, DateTime, Integer, Numeric
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.db.base import Base

class FoodRecord(Base):
    """
    饮食记录主表模型 (Main Food Record Entity)。
    
    架构作用：
    映射数据库中的 `food_records` 表[cite: 2]。用于记录用户某次进餐的总体概况，
    包括用餐时间、餐次类型（早/中/晚）以及通过 AI 汇总计算的总热量和营养素。
    
    设计细节：
    1. 包含 `raw_result_json` 字段[cite: 2]，用于无损备份 AI 识别时的原始原始多模态数据，
       方便后续算法升级后进行重分析。
    2. 与 `FoodRecordItem` 建立一对多关联，通过 record.items 可直接获取本餐的所有食物明细。
    """
    __tablename__ = "food_records"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # 强制关联用户，支持级联删除
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    
    meal_type: Mapped[str] = mapped_column(String(30), nullable=False) # 例如：breakfast, lunch, dinner, snack
    record_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    source_type: Mapped[str] = mapped_column(String(30), nullable=False) # 来源：camera, voice, manual
    description: Mapped[Optional[str]] = mapped_column(Text)
    
    # 宏量营养素统计，映射 SQL 中的 NUMERIC(10, 2)[cite: 2]
    total_calories: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    total_protein_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    total_fat_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    total_carbohydrate_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    
    # AI 原始推理结果备份
    raw_result_json: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default='{}')

    # 系统审计字段[cite: 2]
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # 🔗 ORM 导航属性：定义与明细项的一对多关系
    items: Mapped[List["FoodRecordItem"]] = relationship(
        "FoodRecordItem", back_populates="record", cascade="all, delete-orphan"
    )


class FoodRecordItem(Base):
    """
    饮食记录明细子表模型 (Food Item Detail Entity)。
    
    架构作用：
    映射数据库中的 `food_record_items` 表[cite: 2]。存储单次饮食记录中被拆分出的
    具体每一项食物信息（如：100克米饭、200克牛肉）。
    
    核心功能：
    记录 AI 模型对该单项食物识别的置信度 (`confidence`)[cite: 2]。当置信度低于阈值时，
    前端 Flutter UI 会引导用户进行手动确认，确保数据的绝对准确性。
    """
    __tablename__ = "food_record_items"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # 物理外键：关联所属的饮食记录主表[cite: 2]
    food_record_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("food_records.id", ondelete="CASCADE"), nullable=False, index=True
    )
    
    food_name: Mapped[str] = mapped_column(String(100), nullable=False)
    weight_g: Mapped[Optional[float]] = mapped_column(Numeric(10, 2))
    
    # 该单项食物的营养分解
    calories: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    protein_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    fat_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    carbohydrate_g: Mapped[float] = mapped_column(Numeric(10, 2), default=0.0)
    
    # 算法评估指标
    confidence: Mapped[Optional[float]] = mapped_column(Numeric(5, 4)) # 识别置信度
    meta_json: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default='{}') # 存储食物在图片中的 BBox 等元数据

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # 🔗 ORM 导航属性：反向关联主记录
    record: Mapped["FoodRecord"] = relationship("FoodRecord", back_populates="items")