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
api_router.include_router(users.router, prefix="/users", tags=["Users"])

api_router.include_router(fridge.router, prefix="/fridge", tags=["Fridge"])
api_router.include_router(fridge_items.router, prefix="/fridge/items", tags=["Fridge Items"])
api_router.include_router(fridge_recipe_tasks.router, prefix="/fridge/recipe-tasks", tags=["Fridge Recipe Tasks"])

api_router.include_router(food_records.router, prefix="/food-records", tags=["Food Records"])
api_router.include_router(food_records_compat.router, prefix="/food_records", tags=["Food Records Compat"])

api_router.include_router(recognition.router, prefix="/recognition", tags=["AI Recognition"])
api_router.include_router(health.router, prefix="/health", tags=["Health"])
api_router.include_router(upload.router, prefix="/uploads", tags=["Uploads"])
api_router.include_router(recommendation.router, prefix="/recommendations", tags=["Recommendations"])
api_router.include_router(community.router, prefix="/community", tags=["Community"])
