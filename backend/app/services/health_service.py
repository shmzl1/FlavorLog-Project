# backend/app/services/health_service.py

from sqlalchemy.orm import Session
from app.models.health_feedback import HealthFeedback
from app.schemas.health_feedback import HealthFeedbackCreate

class HealthService:
    @staticmethod
    def create_feedback(db: Session, obj_in: HealthFeedbackCreate, user_id: int) -> HealthFeedback:
        db_obj = HealthFeedback(**obj_in.model_dump(), user_id=user_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def get_user_feedbacks(db: Session, user_id: int, skip: int = 0, limit: int = 100):
        return db.query(HealthFeedback).filter(HealthFeedback.user_id == user_id)\
                 .order_by(HealthFeedback.feedback_time.desc()).offset(skip).limit(limit).all()