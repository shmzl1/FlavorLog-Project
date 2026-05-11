# backend/app/api/router.py

from fastapi import APIRouter
from app.api.v1 import (
    auth,
    users,
    fridge,
    food_records,
    health,
    upload,
    community,
    recognition,
)

api_router = APIRouter()

# 按接口文档挂载鉴权模块到 /auth 路径下
api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])

# 将用户模块挂载到 /users 路径下
api_router.include_router(users.router, prefix="/users", tags=["Users"])

# 冰箱路由，统一加上 /fridge 前缀
api_router.include_router(fridge.router, prefix="/fridge", tags=["Fridge (赛博冰箱)"])

# 挂载饮食记录模块；同时兼容历史下划线路径
api_router.include_router(food_records.router, prefix="/food-records", tags=["Food Records (饮食记录)"])
api_router.include_router(food_records.router, prefix="/food_records", tags=["Food Records (饮食记录)"])

# 💡 2. 新增 AI 识别与极速录入路由
# 挂载后，接口地址将变为：/api/v1/recognition/photo 和 /api/v1/recognition/video-fast-entry
api_router.include_router(recognition.router, prefix="/recognition", tags=["AI Recognition (AI识别服务)"])

# 健康反馈、红黑榜、健康周报
api_router.include_router(health.router, prefix="/health", tags=["Health (健康反馈)"])

# 文件上传模块
api_router.include_router(upload.router, prefix="/uploads", tags=["Uploads (文件上传)"])

# 社区模块
api_router.include_router(community.router, prefix="/community", tags=["Community (社区模块)"])
