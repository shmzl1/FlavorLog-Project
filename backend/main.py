# backend/main.py

import os
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4
import uvicorn

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
    debug=settings.DEBUG,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

_backend_dir = os.path.dirname(os.path.abspath(__file__))
_uploads_dir = os.path.join(_backend_dir, "uploads")
app.mount("/uploads", StaticFiles(directory=_uploads_dir), name="uploads")

# ==========================================
# 3. 跨域安全配置 (CORS)
# ==========================================
app.add_middleware(
    CORSMiddleware,
    # 优先使用 .env 中的配置，如果没有则允许所有 ("*")
    allow_origins=settings.get_cors_origins_list(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================
# 4. 基础探活路由 (Health Check)
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
# 5. 挂载核心业务路由
# ==========================================
# 这里就是打通我们刚才写的 users.py 等业务接口的关键桥梁！
app.include_router(api_router, prefix=settings.API_PREFIX)


# ==========================================
# 6. 本地开发启动入口
# ==========================================
if __name__ == "__main__":
    # 使用 uvicorn 启动，并开启热更新
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
