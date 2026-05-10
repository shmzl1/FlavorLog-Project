from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.recommendation import (
    MenuScanRequest,
    RecommendationRecipeRequest,
    RecommendationTaskResultData,
    RecommendationTaskSubmitData,
)
from app.schemas.recipe_recommendation import RecipeRecommendationResponse
from app.services.recommendation_service import RecommendationService
from app.utils.response import success_response


router = APIRouter()


@router.post("/recipes")
def submit_recommendations(
    payload: RecommendationRecipeRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = RecommendationService.submit_recipe_recommendation(
        db, user_id=current_user.id, payload=payload
    )
    return success_response(
        data=RecommendationTaskSubmitData(
            task_id=task.task_id, status=task.status, message="推荐任务已提交"
        ).model_dump()
    )


@router.get("/tasks/{task_id}")
def get_recommendation_task(
    task_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    task = RecommendationService.get_task(db, user_id=current_user.id, task_id=task_id)
    if not task:
        raise HTTPException(status_code=404, detail="未找到任务或无权访问")

    result = task.result_json if task.status == "success" else None
    return success_response(
        data=RecommendationTaskResultData(
            task_id=task.task_id, status=task.status, result=result
        ).model_dump()
    )


@router.post("/menu-scan")
def menu_scan(
    payload: MenuScanRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        data = RecommendationService.menu_scan(db, user_id=current_user.id, payload=payload)
        return success_response(data=data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/history")
def list_history(
    page: int = 1,
    page_size: int = 10,
    recipe_type: str | None = None,
    task_id: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items, pagination = RecommendationService.list_saved_recipes(
        db,
        user_id=current_user.id,
        page=page,
        page_size=page_size,
        recipe_type=recipe_type,
        task_id=task_id,
    )
    data = {
        "items": [RecipeRecommendationResponse.model_validate(x).model_dump() for x in items],
        "pagination": pagination,
    }
    return success_response(data=data)


@router.get("/recipes/{recipe_id}")
def get_recipe(
    recipe_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rec = RecommendationService.get_saved_recipe(db, user_id=current_user.id, recipe_id=recipe_id)
    if not rec:
        raise HTTPException(status_code=404, detail="未找到资源或无权访问")
    return success_response(data=RecipeRecommendationResponse.model_validate(rec).model_dump())


@router.get("/dashboard")
def dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    data = RecommendationService.get_dashboard(db, user_id=current_user.id)
    payload = {
        "latest_menu_scan": data["latest_menu_scan"],
        "latest_recommendations": [
            RecipeRecommendationResponse.model_validate(x).model_dump()
            for x in data["latest_recommendations"]
        ],
        "latest_fridge_recipes": [
            RecipeRecommendationResponse.model_validate(x).model_dump()
            for x in data["latest_fridge_recipes"]
        ],
    }
    return success_response(data=payload)
