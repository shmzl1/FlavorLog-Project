from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.fridge_recipe_task import (
    FridgeRecipeTaskRequest,
    FridgeRecipeTaskResultData,
    FridgeRecipeTaskSubmitData,
)
from app.services.fridge_recipe_service import FridgeRecipeService
from app.utils.response import success_response


router = APIRouter()


@router.post("", status_code=status.HTTP_200_OK)
def submit_task(
    payload: FridgeRecipeTaskRequest,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    task = FridgeRecipeService.submit_task(db, user_id=current_user.id, payload=payload)
    data = FridgeRecipeTaskSubmitData(
        task_id=task.task_id,
        status=task.status,
        message="食谱生成任务已提交",
    ).model_dump()
    return success_response(data=data)


@router.get("/{task_id}", status_code=status.HTTP_200_OK, responses={404: {"description": "Not Found"}})
def get_task(
    task_id: str,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    task = FridgeRecipeService.get_task(db, user_id=current_user.id, task_id=task_id)
    if not task:
        raise HTTPException(status_code=404, detail="未找到任务或无权访问")

    result = task.result_json if task.status == "success" else None
    data = FridgeRecipeTaskResultData(
        task_id=task.task_id,
        status=task.status,
        result=result,
    ).model_dump()
    return success_response(data=data)
