# backend/app/models/ai_task.py

from datetime import datetime
from typing import Optional
from sqlalchemy import String, Text, ForeignKey, DateTime, Integer
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func
from app.db.base import Base

class AITask(Base):
    """
    AI 异步任务状态追踪模型。
    
    作用：
    映射 `ai_tasks` 表[cite: 2]。由于多模态模型（视觉检测、语音对齐）处理时间较长，
    我们不能让用户在前端阻塞等待。该模型用于实现“异步轮询”架构：
    1. 前端上传数据，后端立即返回 task_id 并启动后台进程。
    2. 算法模块实时更新此表的 `status`（pending, processing, completed, failed）。
    3. 前端根据状态展示加载动画或最终结果 `result_json`[cite: 2]。
    """
    __tablename__ = "ai_tasks"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    task_id: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # 任务分类：food_detection (视觉), audio_alignment (多模态), recipe_gen (LLM)
    task_type: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(String(30), default="pending")
    
    # 数据载体：存储任务的输入参数与最终模型输出的原始 JSON
    input_json: Mapped[dict] = mapped_column(JSONB, default=dict, server_default='{}')
    result_json: Mapped[dict] = mapped_column(JSONB, default=dict, server_default='{}')
    error_message: Mapped[Optional[str]] = mapped_column(Text)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())