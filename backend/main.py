# backend/main.py

import os
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4
import uvicorn

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
# 💡 新增导入：用于挂载静态文件目录
from fastapi.staticfiles import StaticFiles

# 导入我们的全局配置和路由总线
from app.core.config import settings
from app.api.router import api_router

# ==========================================
# 1. 企业级统一响应结构
# ==========================================
def success_response(data: Any = None, message: str = "success") -> dict:
    """
    统一 API 返回格式。
    方便前端 Flutter 侧进行统一的 JSON 解析和异常拦截。
    """
    return {
        "code": 0,
        "message": message,
        "data": data,
        "request_id": str(uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

# ==========================================
# 2. FastAPI 实例初始化
# ==========================================
app = FastAPI(
    title=settings.APP_NAME,
    description="知味志 FlavorLog 后端接口文档。所有核心业务接口以 /api/v1 开头。",
    version=settings.APP_VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# ==========================================
# 3. 跨域安全配置 (CORS)
# ==========================================
app.add_middleware(
    CORSMiddleware,
    # 优先使用 .env 中的配置，如果没有则允许所有 ("*")
    allow_origins=[str(origin) for origin in settings.CORS_ALLOW_ORIGINS] if settings.CORS_ALLOW_ORIGINS else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# 4. 💡 静态资源映射 (非常重要)
# ==========================================
# 确保物理文件夹存在，否则 FastAPI 挂载时会报错崩溃
os.makedirs("uploads/images", exist_ok=True)
os.makedirs("uploads/videos", exist_ok=True)
os.makedirs("uploads/audios", exist_ok=True)

# 告诉 FastAPI：当有人访问 /uploads 开头的网址时，直接去本地的 uploads 文件夹拿文件给他
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


# ==========================================
# 5. 基础探活路由 (Health Check)
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
    return success_response(
        data={
            "status": "ok",
            "service": "flavorlog-backend",
        }
    )

@app.get(f"{settings.API_PREFIX}/health")
def api_health_check():
    return success_response(
        data={
            "status": "ok",
            "service": "flavorlog-backend",
            "api_prefix": settings.API_PREFIX,
        }
    )

# ==========================================
# 6. 挂载核心业务路由
# ==========================================
# 这里就是打通我们刚才写的 users.py 等业务接口的关键桥梁！
app.include_router(api_router, prefix=settings.API_PREFIX)


# ==========================================
# 7. 本地开发启动入口
# ==========================================
if __name__ == "__main__":
    # 使用 uvicorn 启动，并开启热更新
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)