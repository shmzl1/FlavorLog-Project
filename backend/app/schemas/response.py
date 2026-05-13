# backend/app/schemas/response.py

from datetime import datetime, timezone
from typing import Generic, TypeVar, Optional, Any
from uuid import uuid4
from pydantic import BaseModel,Field

# 定义一个泛型变量 T，代表将来要装入 data 里的任意类型格式
T = TypeVar("T")

class StandardResponse(BaseModel, Generic[T]):
    """
    全局统一的 API 响应包裹格式。
    所有的接口返回都必须套上这个壳子，保证前后端对接的契约统一。
    """
    code: int = 0
    message: str = "success"
    data: Optional[T] = None
    request_id: str
    timestamp: str


class ErrorResponse(StandardResponse[Any]):
    errors: list[dict[str, Any]] = Field(default_factory=list)

def success_response(data: Any = None, msg: str = "success") -> StandardResponse:
    """快捷生成成功响应的工具函数"""
    return StandardResponse(
        code=0,
        message=msg,
        data=data,
        request_id=str(uuid4()),
        timestamp=datetime.now(timezone.utc).isoformat(),
    )

def error_response(
    code: int = 40001,
    msg: str = "参数错误",
    data: Any = None,
    errors: Optional[list[dict[str, Any]]] = None,
) -> ErrorResponse:
    """快捷生成失败响应的工具函数"""
    return ErrorResponse(
        code=code,
        message=msg,
        data=data,
        errors=errors or [],
        request_id=str(uuid4()),
        timestamp=datetime.now(timezone.utc).isoformat(),
    )
