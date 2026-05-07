# backend/app/models/fridge_item.py

from datetime import date, datetime
from typing import Optional
from sqlalchemy import String, Numeric, Text, ForeignKey, Date, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.db.base import Base

class FridgeItem(Base):
    """
    赛博冰箱（虚拟库存）实体模型。
    
    作用：
    映射 `fridge_items` 表[cite: 2]。记录用户拥有的食材详情。
    核心逻辑在于 `expire_date`[cite: 2]，后端会自动扫描此字段，
    对即将过期的食材进行预警，并优先将这些食材作为推荐食谱的原材料。
    """
    __tablename__ = "fridge_items"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    name: Mapped[str] = mapped_column(String(100), nullable=False) # 食材名称
    category: Mapped[Optional[str]] = mapped_column(String(50)) # 蔬菜、肉类、海鲜等
    
    # 数量与重量的双重追踪
    quantity: Mapped[float] = mapped_column(Numeric(10, 2), default=1)
    unit: Mapped[Optional[str]] = mapped_column(String(30)) # 个、袋、瓶
    weight_g: Mapped[Optional[float]] = mapped_column(Numeric(10, 2)) # 辅助重量参考
    
    expire_date: Mapped[Optional[date]] = mapped_column(Date, index=True) # 过期日期提醒
    storage_location: Mapped[Optional[str]] = mapped_column(String(50)) # 冷藏、冷冻、常温
    remark: Mapped[Optional[str]] = mapped_column(Text)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())