from datetime import date, datetime, time, timedelta, timezone

from sqlalchemy.orm import Session

from app.algorithms.apriori.food_blacklist import rank_foods_by_feedback
from app.models.food_record import FoodRecord, FoodRecordItem
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
        return (
            db.query(HealthFeedback)
            .filter(HealthFeedback.user_id == user_id)
            .order_by(HealthFeedback.feedback_time.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    @staticmethod
    def get_user_feedbacks_by_date(
        db: Session,
        user_id: int,
        skip: int = 0,
        limit: int = 100,
        start_date: date | None = None,
        end_date: date | None = None,
    ):
        query = db.query(HealthFeedback).filter(HealthFeedback.user_id == user_id)
        if start_date:
            query = query.filter(HealthFeedback.feedback_time >= datetime.combine(start_date, time.min))
        if end_date:
            query = query.filter(HealthFeedback.feedback_time <= datetime.combine(end_date, time.max))
        return query.order_by(HealthFeedback.feedback_time.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def get_food_blacklist(db: Session, user_id: int) -> dict:
        pairs = (
            db.query(FoodRecordItem, HealthFeedback)
            .join(FoodRecord, FoodRecordItem.food_record_id == FoodRecord.id)
            .outerjoin(HealthFeedback, HealthFeedback.food_record_id == FoodRecord.id)
            .filter(FoodRecord.user_id == user_id)
            .all()
        )
        ranked = rank_foods_by_feedback(pairs)
        if not ranked["black_items"] and not ranked["red_items"]:
            ranked = HealthService._mock_blacklist()
        ranked["generated_at"] = datetime.now(timezone.utc)
        return ranked

    @staticmethod
    def get_weekly_report(db: Session, user_id: int, week_start: date | None = None) -> dict:
        if week_start is None:
            today = date.today()
            week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=6)
        start_dt = datetime.combine(week_start, time.min)
        end_dt = datetime.combine(week_end, time.max)

        records = (
            db.query(FoodRecord)
            .filter(
                FoodRecord.user_id == user_id,
                FoodRecord.record_time >= start_dt,
                FoodRecord.record_time <= end_dt,
            )
            .order_by(FoodRecord.record_time.asc())
            .all()
        )

        totals_by_day = {week_start + timedelta(days=i): 0.0 for i in range(7)}
        protein_total = 0.0
        for record in records:
            day = record.record_time.date()
            totals_by_day[day] = totals_by_day.get(day, 0.0) + float(record.total_calories or 0)
            protein_total += float(record.total_protein_g or 0)

        active_days = max(1, len([value for value in totals_by_day.values() if value > 0]))
        avg_calories = round(sum(totals_by_day.values()) / active_days, 1)
        avg_protein = round(protein_total / active_days, 1)

        warnings = []
        suggestions = []
        if avg_calories > 2200:
            warnings.append("本周平均热量偏高，晚餐和加餐可以适当收敛")
        if avg_protein < 60:
            warnings.append("本周蛋白质摄入偏低")
            suggestions.append("早餐或午餐增加鸡蛋、豆制品、鱼肉等优质蛋白")
        if not records:
            suggestions.append("暂无本周饮食记录，已返回演示用周报结构")
        suggestions.append("继续记录餐后反馈，红黑榜会更准确")

        return {
            "week_start": week_start,
            "week_end": week_end,
            "avg_calories": avg_calories,
            "avg_protein_g": avg_protein,
            "calorie_trend": [
                {"date": day, "calories": round(calories, 1)}
                for day, calories in totals_by_day.items()
            ],
            "warnings": warnings,
            "suggestions": suggestions,
        }

    @staticmethod
    def _mock_blacklist() -> dict:
        return {
            "black_items": [
                {
                    "food_name": "奶茶",
                    "reason": "演示数据中与疲劳和腹胀反馈关联较高",
                    "support": 0.31,
                    "confidence": 0.74,
                    "suggestion": "建议减少甜饮频率，替换为无糖茶或温水",
                }
            ],
            "red_items": [
                {
                    "food_name": "鸡胸肉",
                    "reason": "高蛋白且近期负反馈较少",
                    "score": 0.89,
                },
                {
                    "food_name": "西兰花",
                    "reason": "蔬菜摄入友好，热量较低",
                    "score": 0.82,
                },
            ],
        }
