# backend/app/schemas/response.py

from typing import Generic, TypeVar, Optional, Any
from pydantic import BaseModel

# 定义一个泛型变量 T，代表将来要装入 data 里的任意类型格式
T = TypeVar("T")

class StandardResponse(BaseModel, Generic[T]):
    """
    全局统一的 API 响应包裹格式。
    所有的接口返回都必须套上这个壳子，保证前后端对接的契约统一。
    """
    code: int = 200
    msg: str = "success"
    data: Optional[T] = None

def success_response(data: Any = None, msg: str = "操作成功") -> StandardResponse:
    """快捷生成成功响应的工具函数"""
    return StandardResponse(code=200, msg=msg, data=data)

def error_response(code: int = 400, msg: str = "操作失败", data: Any = None) -> StandardResponse:
    """快捷生成失败响应的工具函数"""
    return StandardResponse(code=code, msg=msg, data=data)