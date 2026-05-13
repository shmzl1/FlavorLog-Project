# backend/main.py

import os
import asyncio
from datetime import datetime, timezone
from typing import Any
from uuid import uuid4
import uvicorn

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles

from app.schemas.response import error_response
from app.utils.logger import logger
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

    redis_ready = False
    sync_task = None

    try:
        await redis_client.ping()  # type: ignore
        redis_ready = True
        print("✅ Redis 连接成功！")
    except Exception as e:
        print(f"⚠️ Redis 未启动，阶段一将跳过 Redis 后台任务: {e}")

    if redis_ready:
        sync_task = asyncio.create_task(sync_likes_to_db())

    yield

    if sync_task:
        sync_task.cancel()
        try:
            await sync_task
        except asyncio.CancelledError:
            print("🛑 后台同步任务已安全停止")

    if redis_ready:
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
    lifespan=lifespan
)


def _biz_code_from_status(http_status: int) -> int:
    """将 HTTP 状态码映射为项目内部业务 code。"""
    mapping = {
        status.HTTP_400_BAD_REQUEST: 40001,
        status.HTTP_401_UNAUTHORIZED: 40101,
        status.HTTP_403_FORBIDDEN: 40301,
        status.HTTP_404_NOT_FOUND: 40401,
        status.HTTP_409_CONFLICT: 40901,
        status.HTTP_422_UNPROCESSABLE_ENTITY: 40001,
        status.HTTP_500_INTERNAL_SERVER_ERROR: 50001,
    }
    return mapping.get(http_status, 50001 if http_status >= 500 else 40001)


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """统一处理业务主动抛出的 HTTPException。"""
    message = exc.detail if isinstance(exc.detail, str) else "请求处理失败"
    body = error_response(
        code=_biz_code_from_status(exc.status_code),
        msg=message,
        data=None,
        errors=None,
    )
    return JSONResponse(
        status_code=exc.status_code,
        content=body.model_dump(mode="json"),
        headers=getattr(exc, "headers", None),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """统一处理请求参数校验错误，例如缺字段、类型错误、邮箱格式错误。"""
    errors = []
    for err in exc.errors():
        loc = ".".join(str(item) for item in err.get("loc", []))
        errors.append(
            {
                "field": loc,
                "reason": err.get("msg", "参数错误"),
            }
        )

    body = error_response(
        code=40001,
        msg="参数错误",
        data=None,
        errors=errors,
    )
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=body.model_dump(mode="json"),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    """统一处理未预期异常，避免直接把 Traceback 暴露给前端。"""
    logger.exception("未处理的服务器异常: %s", exc)

    body = error_response(
        code=50001,
        msg="服务器内部错误",
        data=None,
        errors=None,
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=body.model_dump(mode="json"),
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
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
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
