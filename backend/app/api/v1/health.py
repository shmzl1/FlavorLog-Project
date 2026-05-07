# backend/app/api/v1/health.py

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_db, get_current_user
from app.schemas.response import StandardResponse, success_response
from app.schemas.health_feedback import HealthFeedbackCreate, HealthFeedbackResponse
from app.services.health_service import HealthService
from app.models.user import User

router = APIRouter()

@router.post("/", response_model=StandardResponse[HealthFeedbackResponse])
def add_health_feedback(
    obj_in: HealthFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """记录一次餐后健康反馈"""
    feedback = HealthService.create_feedback(db, obj_in=obj_in, user_id=current_user.id)
    return success_response(data=feedback)

@router.get("/", response_model=StandardResponse[List[HealthFeedbackResponse]])
def read_my_feedbacks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """查看我的健康反馈历史"""
    feedbacks = HealthService.get_user_feedbacks(db, user_id=current_user.id)
    return success_response(data=feedbacks)