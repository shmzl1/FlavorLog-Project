# backend/app/api/router.py

from fastapi import APIRouter
from app.api.v1 import users
from app.api.v1 import fridge
from app.api.v1 import food_records
from app.api.v1 import health
from app.api.v1 import upload
from app.api.v1 import community

api_router = APIRouter()

# 将用户模块挂载到 /users 路径下
api_router.include_router(users.router, prefix="/users", tags=["Users"])

# 👈 新增冰箱路由，统一加上 /fridge 前缀
api_router.include_router(fridge.router, prefix="/fridge", tags=["Fridge (赛博冰箱)"])

# 挂载饮食记录模块
api_router.include_router(food_records.router, prefix="/food_records", tags=["Food Records (饮食记录)"])

api_router.include_router(health.router, prefix="/health", tags=["Health (健康反馈)"])

api_router.include_router(upload.router, prefix="/uploads", tags=["Uploads (文件上传)"])

api_router.include_router(community.router, prefix="/community", tags=["Community (社区模块)"])