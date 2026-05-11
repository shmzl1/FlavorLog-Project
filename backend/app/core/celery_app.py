# backend/app/core/celery_app.py
import os
from celery import Celery

"""
【Celery 异步任务队列配置中心】

核心作用：
配置 Celery 实例，连接 Redis 作为 Message Broker（消息中间件）和 Result Backend（结果存储）。
这里负责定义后台 Worker 的运行规则，特别是针对重度 AI 任务的资源隔离与释放策略。
"""

redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")

celery_app = Celery(
    "flavorlog_worker",
    broker=redis_url,
    backend=redis_url,
    include=["app.tasks.video_tasks"] # 注册任务模块
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Shanghai",
    enable_utc=True,
    
    # ==========================================
    # 【核心：防止 AI 模型内存/显存泄漏的工业级方案】
    # 作用：规定每个 Worker 进程在处理完多少个任务后，必须强制重启（销毁当前进程并拉起新进程）。
    # 原理：Python 的深度学习库（如 PyTorch）在运行 YOLO 或 Whisper 时会产生大量显存碎片，
    # 依靠 Python 自身的 gc.collect() 往往无法彻底清空。
    # 方案：设置一个较小的值（例如 10）。Worker 处理完 10 个视频后自尽，OS 会无条件收回所有 RAM 和 VRAM，
    # 从而从物理层面 100% 杜绝内存泄漏。
    # ==========================================
    worker_max_tasks_per_child=10,
    
    # 防止单个超大视频卡死队列，设置硬超时时间（例如 10 分钟）
    task_time_limit=600,
    task_soft_time_limit=540,
)