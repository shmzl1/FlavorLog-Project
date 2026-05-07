# backend/app/models/upload.py

from datetime import datetime
from typing import Optional
from sqlalchemy import String, ForeignKey, DateTime, Integer, BigInteger, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.db.base import Base

class UploadFile(Base):
    """
    多模态文件资产管理模型 (Asset Management Entity)。
    
    作用：
    映射 `upload_files` 表[cite: 2]。用于管理用户上传的所有原始素材（图片、音频、短视频）。
    
    设计细节：
    1. `file_url`: 存储文件在服务器或云存储（如 OSS/S3）的访问地址。
    2. `scene`: 标记文件用途（如 'avatar', 'food_record', 'community_post'），方便后续进行冷热数据迁移或清理。
    3. `size_bytes`: 使用 BigInteger 存储，防止视频文件大小溢出普通整数范围[cite: 2]。
    """
    __tablename__ = "upload_files"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_url: Mapped[str] = mapped_column(Text, nullable=False)
    file_type: Mapped[str] = mapped_column(String(30), nullable=False) # image, audio, video
    mime_type: Mapped[Optional[str]] = mapped_column(String(100))
    size_bytes: Mapped[int] = mapped_column(BigInteger)
    
    scene: Mapped[Optional[str]] = mapped_column(String(50))
    meta_json: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default='{}')
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )