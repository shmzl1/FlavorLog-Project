from datetime import datetime, timedelta, timezone

from app.db.session import DatabaseManager
from app.core.config import settings
from app.models.food_record import FoodRecord, FoodRecordItem
from app.models.health_feedback import HealthFeedback
from app.models.taste import TasteVector
from app.models.user import User
from app.algorithms.matching.taste_match import build_taste_vector


MOCK_MEALS = {
    "lin_demo": [
        ("breakfast", ["鸡蛋", "牛奶", "全麦面包"], 520, 31, 16, 58, 2, 1, []),
        ("lunch", ["鸡胸肉", "西兰花", "米饭"], 680, 48, 12, 82, 1, 1, []),
        ("dinner", ["火锅", "奶茶"], 1180, 35, 52, 120, 7, 6, ["bloating"]),
        ("lunch", ["鱼肉", "沙拉", "米饭"], 610, 42, 10, 72, 1, 2, []),
    ],
    "protein_buddy": [
        ("breakfast", ["鸡蛋", "豆腐"], 410, 34, 14, 24, 1, 1, []),
        ("lunch", ["鸡胸肉", "西兰花"], 560, 52, 9, 38, 1, 1, []),
    ],
    "light_buddy": [
        ("breakfast", ["燕麦", "牛奶"], 430, 18, 10, 62, 2, 2, []),
        ("dinner", ["豆腐", "沙拉", "鱼肉"], 520, 39, 13, 36, 1, 1, []),
    ],
}


def seed_mock_food_records() -> None:
    db = next(DatabaseManager(settings.DATABASE_URL).get_db_session())
    try:
        now = datetime.now(timezone.utc)
        for username, meals in MOCK_MEALS.items():
            user = db.query(User).filter(User.username == username).first()
            if user is None:
                continue

            existing_count = db.query(FoodRecord).filter(FoodRecord.user_id == user.id).count()
            if existing_count:
                continue

            all_food_names = []
            for index, meal in enumerate(meals):
                meal_type, food_names, calories, protein, fat, carbs, bloating, fatigue, symptoms = meal
                record = FoodRecord(
                    user_id=user.id,
                    meal_type=meal_type,
                    record_time=now - timedelta(days=3 - index),
                    source_type="mock",
                    description="林宸宇负责模块演示数据",
                    total_calories=calories,
                    total_protein_g=protein,
                    total_fat_g=fat,
                    total_carbohydrate_g=carbs,
                    raw_result_json={"provider": "mock"},
                )
                db.add(record)
                db.flush()

                for food_name in food_names:
                    all_food_names.append(food_name)
                    db.add(FoodRecordItem(
                        food_record_id=record.id,
                        food_name=food_name,
                        weight_g=120,
                        calories=round(calories / len(food_names), 2),
                        protein_g=round(protein / len(food_names), 2),
                        fat_g=round(fat / len(food_names), 2),
                        carbohydrate_g=round(carbs / len(food_names), 2),
                        confidence=0.95,
                        meta_json={"source": "mock"},
                    ))

                db.add(HealthFeedback(
                    user_id=user.id,
                    food_record_id=record.id,
                    feedback_time=record.record_time + timedelta(hours=2),
                    bloating_level=bloating,
                    fatigue_level=fatigue,
                    mood="normal" if bloating < 6 else "low",
                    digestive_note="演示反馈",
                    extra_symptoms=symptoms,
                ))

            vector, tags = build_taste_vector(all_food_names)
            taste_vector = db.query(TasteVector).filter(TasteVector.user_id == user.id).first()
            if taste_vector is None:
                taste_vector = TasteVector(user_id=user.id)
                db.add(taste_vector)
            taste_vector.vector_json = vector
            taste_vector.tags = tags
            taste_vector.updated_source = "mock_food_records"

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    seed_mock_food_records()
    print("Mock food records, health feedbacks and taste vectors seeded.")
