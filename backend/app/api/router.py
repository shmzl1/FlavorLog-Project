# backend/app/api/router.py

from fastapi import APIRouter
from app.api.v1 import (
    auth,
    users,
    fridge,
    fridge_items,
    fridge_recipe_tasks,
    food_records,
    food_records_compat,
    health,
    upload,
    recommendation,
    community,
    recognition,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])

# 将用户模块挂载到 /users 路径下
api_router.include_router(users.router, prefix="/users", tags=["Users"])

# 冰箱路由，统一加上 /fridge 前缀
api_router.include_router(fridge.router, prefix="/fridge", tags=["Fridge (赛博冰箱)"])
api_router.include_router(fridge_items.router, prefix="/fridge/items", tags=["Fridge Items (兼容)"])
api_router.include_router(fridge_recipe_tasks.router, prefix="/fridge/recipe-tasks", tags=["Fridge Recipe Tasks"])

api_router.include_router(food_records.router, prefix="/food-records", tags=["Food Records (饮食记录)"])
api_router.include_router(food_records_compat.router, prefix="/food_records", tags=["Food Records (兼容)"])

api_router.include_router(recognition.router, prefix="/recognition", tags=["AI Recognition (AI识别服务)"])

api_router.include_router(health.router, prefix="/health/feedbacks", tags=["Health Feedbacks (健康反馈)"])
api_router.include_router(health.router, prefix="/health", tags=["Health (健康反馈)"])

api_router.include_router(upload.router, prefix="/uploads", tags=["Uploads (文件上传)"])

api_router.include_router(recommendation.router, prefix="/recommendations", tags=["Recommendations (推荐)"])
api_router.include_router(community.router, prefix="/community", tags=["Community (社区模块)"])
