# backend/app/api/router.py

from fastapi import APIRouter
from app.api.v1 import users

api_router = APIRouter()

# 将用户模块挂载到 /users 路径下
api_router.include_router(users.router, prefix="/users", tags=["Users"])