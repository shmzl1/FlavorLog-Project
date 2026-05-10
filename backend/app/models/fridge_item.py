# backend/app/models/fridge_item.py

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.base import Base # 假设你的基类在这里，如果不同请自行调整

class FridgeItem(Base):
    """赛博冰箱食材数据库模型"""
    __tablename__ = "fridge_items"

    id = Column(Integer, primary_key=True, index=True)
    
    # 💡 优化：直接写上 ForeignKey 约束，保证数据库表间关系的绝对安全
    user_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=False) 
    
    name = Column(String, index=True, nullable=False)
    category = Column(String, default="其他")
    quantity = Column(Float, default=1.0)
    unit = Column(String, default="个")
    
    # 过期时间字段
    expiration_date = Column(DateTime(timezone=True), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())