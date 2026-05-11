from datetime import date
from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.health import FoodBlacklistResponse, WeeklyReportResponse
from app.schemas.health_feedback import HealthFeedbackCreate, HealthFeedbackResponse
from app.schemas.response import StandardResponse, success_response
from app.services.health_service import HealthService

router = APIRouter()


@router.post("/", response_model=StandardResponse[HealthFeedbackResponse])
def add_health_feedback(
    obj_in: HealthFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """记录一次餐后健康反馈"""
    feedback = HealthService.create_feedback(db, obj_in=obj_in, user_id=current_user.id)
    return success_response(data=feedback)


@router.get("/", response_model=StandardResponse[List[HealthFeedbackResponse]])
def read_my_feedbacks(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """查看我的健康反馈历史"""
    feedbacks = HealthService.get_user_feedbacks(db, user_id=current_user.id)
    return success_response(data=feedbacks)


@router.get("/feedbacks", response_model=StandardResponse[List[HealthFeedbackResponse]])
def read_feedbacks_by_page(
    page: int = Query(1, ge=1),
    page_size: int = Query(10, ge=1, le=100),
    start_date: date | None = None,
    end_date: date | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    feedbacks = HealthService.get_user_feedbacks_by_date(
        db,
        user_id=current_user.id,
        skip=(page - 1) * page_size,
        limit=page_size,
        start_date=start_date,
        end_date=end_date,
    )
    return success_response(data=feedbacks)


@router.get("/blacklist", response_model=StandardResponse[FoodBlacklistResponse])
def read_food_blacklist(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    data = HealthService.get_food_blacklist(db, user_id=current_user.id)
    return success_response(data=data)


@router.get("/weekly-report", response_model=StandardResponse[WeeklyReportResponse])
def read_weekly_report(
    week_start: date | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    data = HealthService.get_weekly_report(db, user_id=current_user.id, week_start=week_start)
    return success_response(data=data)
