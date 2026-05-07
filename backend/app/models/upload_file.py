# backend/app/models/upload_file.py

from datetime import datetime
from typing import Optional
from sqlalchemy import String, Text, ForeignKey, DateTime, BigInteger
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from app.db.base import Base

class UploadFileModel(Base):
    """
    上传文件记录表 (对应数据库 upload_files 表)
    """
    __tablename__ = "upload_files"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_url: Mapped[str] = mapped_column(Text, nullable=False) # 物理存储路径或 URL
    file_type: Mapped[str] = mapped_column(String(30), nullable=False) # image, video, audio
    
    mime_type: Mapped[Optional[str]] = mapped_column(String(100))
    size_bytes: Mapped[Optional[int]] = mapped_column(BigInteger)
    
    scene: Mapped[Optional[str]] = mapped_column(String(50)) # 场景：food, avatar, menu
    meta_json: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default='{}')

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())