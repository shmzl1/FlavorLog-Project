# backend/main.py

import os
import asyncio
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4
import uvicorn

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from contextlib import asynccontextmanager
from app.core.redis import redis_client
from app.core.tasks import sync_likes_to_db  # 💡 导入“扫地僧”任务

# 导入我们的全局配置和路由总线
from app.core.config import settings
from app.api.router import api_router

# ==========================================
# 1. 企业级统一响应结构
# ==========================================
def success_response(data: Any = None, message: str = "success") -> dict:
    return {
        "code": 0,
        "message": message,
        "data": data,
        "request_id": str(uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

# ==========================================
# 💡 2. 生命周期管理 (开机连 Redis，并启动后台任务)
# ==========================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("🚀 正在连接 Redis 高并发引擎...")
    try:
        await redis_client.ping() # type: ignore
        print("✅ Redis 连接成功！")
    except Exception as e:
        print(f"❌ Redis 未启动，将降级为数据库模式: {e}")
    
    # 💡 启动后台同步任务 (交给系统的异步循环管理)
    sync_task = asyncio.create_task(sync_likes_to_db())
    
    yield # 交出控制权，应用正式运行
    
    # 💡 关闭时：安全退出后台任务和 Redis 连接
    sync_task.cancel()
    try:
        await sync_task
    except asyncio.CancelledError:
        print("🛑 后台同步任务已安全停止")
        
    await redis_client.aclose()
    print("🛑 Redis 连接已释放")

# ==========================================
# 3. FastAPI 实例初始化
# ==========================================
app = FastAPI(
    title=settings.APP_NAME,
    description="知味志 FlavorLog 后端接口文档。所有核心业务接口以 /api/v1 开头。",
    version=settings.APP_VERSION,
    debug=settings.DEBUG,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan # 💡 挂载生命周期
)

_backend_dir = os.path.dirname(os.path.abspath(__file__))
_uploads_dir = os.path.join(_backend_dir, "uploads")
os.makedirs(os.path.join(_uploads_dir, "images"), exist_ok=True)
os.makedirs(os.path.join(_uploads_dir, "videos"), exist_ok=True)
os.makedirs(os.path.join(_uploads_dir, "audios"), exist_ok=True)
app.mount("/uploads", StaticFiles(directory=_uploads_dir), name="uploads")

# ==========================================
# 4. 跨域安全配置 (CORS)
# ==========================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_cors_origins_list(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==========================================
# 6. 基础探活路由
# ==========================================
@app.get("/")
def root():
    return success_response(
        data={
            "name": settings.APP_NAME,
            "version": settings.APP_VERSION,
            "docs": "/docs",
            "api_prefix": settings.API_PREFIX,
        }
    )

@app.get("/health")
def health_check():
    return success_response(data={"status": "ok", "service": "flavorlog-backend"})

@app.get(f"{settings.API_PREFIX}/health")
def api_health_check():
    return success_response(data={"status": "ok", "api_prefix": settings.API_PREFIX})

# ==========================================
# 7. 挂载核心业务路由
# ==========================================
app.include_router(api_router, prefix=settings.API_PREFIX)


# ==========================================
# 8. 本地开发启动入口
# ==========================================
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
