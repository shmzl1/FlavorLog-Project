from app.core.security import pwd_hasher
from app.db.session import DatabaseManager
from app.core.config import settings
from app.models.user import User


MOCK_USERS = [
    {
        "username": "lin_demo",
        "email": "lin_demo@flavorlog.local",
        "nickname": "林宸宇演示号",
        "health_goal": "lose_fat",
        "diet_preference": ["高蛋白", "低脂", "清淡"],
        "allergens": ["花生"],
    },
    {
        "username": "protein_buddy",
        "email": "protein_buddy@flavorlog.local",
        "nickname": "低脂搭子",
        "health_goal": "lose_fat",
        "diet_preference": ["高蛋白", "低脂"],
        "allergens": [],
    },
    {
        "username": "light_buddy",
        "email": "light_buddy@flavorlog.local",
        "nickname": "清淡饭友",
        "health_goal": "maintain",
        "diet_preference": ["清淡", "蔬菜友好"],
        "allergens": [],
    },
]


def seed_mock_users() -> None:
    db = next(DatabaseManager(settings.DATABASE_URL).get_db_session())
    try:
        for item in MOCK_USERS:
            user = db.query(User).filter(User.username == item["username"]).first()
            if user is None:
                user = User(
                    username=item["username"],
                    email=item["email"],
                    password_hash=pwd_hasher.get_password_hash("123456"),
                )
                db.add(user)
            user.nickname = item["nickname"]
            user.health_goal = item["health_goal"]
            user.diet_preference = item["diet_preference"]
            user.allergens = item["allergens"]
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    seed_mock_users()
    print("Mock users seeded. Password for all mock users: 123456")
