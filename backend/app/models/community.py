# backend/app/models/community.py

from datetime import datetime
from typing import List, Optional
# 💡 核心修复：从 postgresql 方言包中导入 JSONB
from sqlalchemy.dialects.postgresql import JSONB 
from sqlalchemy import String, Text, ForeignKey, DateTime, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func
from app.db.base import Base

class CommunityPost(Base):
    """
    社区动态实体模型。
    
    架构作用：
    映射数据库中的 `community_posts` 表。
    它是用户分享饮食社交的核心载体。该类通过 SQLAlchemy 2.0 的 
    Declarative Mapping 方式定义，支持强类型检查和自动化的数据库迁移。
    """
    __tablename__ = "community_posts"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # 关联饮食记录（可选）
    food_record_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("food_records.id", ondelete="SET NULL"), nullable=True
    )
    
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[Optional[str]] = mapped_column(Text)
    
    # 💡 核心修复：JSONB 在这里作为具体的列类型使用
    # Mapped[list] 表明在 Python 中它是一个列表
    image_urls: Mapped[list] = mapped_column(JSONB, server_default='[]')
    
    like_count: Mapped[int] = mapped_column(default=0)
    
    # 💡 核心修复：Mapped 括号内写 datetime 类型，func.now() 放在右侧作为默认值
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now()  # 这里的 func.now 负责在数据库生成时间
    )
    
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        onupdate=func.now()
    )

    def __repr__(self) -> str:
        """
        调试友好的对象打印函数。
        
        作用：
        当你在终端或日志中打印这个对象时，能一眼看到帖子的标题，
        而不是看到一串晦涩的对象内存地址。
        """
        return f"<CommunityPost(title={self.title})>"