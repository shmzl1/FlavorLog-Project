from app.db.session import DatabaseManager
from app.core.config import settings
from app.models.community import CommunityPost
from app.models.food_record import FoodRecord
from app.models.user import User


MOCK_POSTS = [
    ("lin_demo", "今天的低脂午餐", "鸡胸肉、西兰花和米饭，餐后反馈很稳定。", ["高蛋白", "低脂"]),
    ("protein_buddy", "高蛋白便当", "适合减脂期，红榜食材可以优先参考。", ["高蛋白", "便当"]),
    ("light_buddy", "清淡晚餐记录", "豆腐、沙拉和鱼肉，适合轻负担晚餐。", ["清淡", "蔬菜友好"]),
]


def seed_mock_posts() -> None:
    db = next(DatabaseManager(settings.DATABASE_URL).get_db_session())
    try:
        for username, title, content, tags in MOCK_POSTS:
            user = db.query(User).filter(User.username == username).first()
            if user is None:
                continue
            exists = (
                db.query(CommunityPost)
                .filter(CommunityPost.user_id == user.id, CommunityPost.title == title)
                .first()
            )
            if exists:
                continue
            db.add(CommunityPost(
                user_id=user.id,
                title=title,
                content=content,
                image_urls=[],
                tags=tags,
                visibility="public",
                like_count=2,
                comment_count=1,
                fork_count=0,
            ))
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    seed_mock_posts()
    print("Mock community posts seeded.")
