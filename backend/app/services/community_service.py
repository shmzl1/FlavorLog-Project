from fastapi import HTTPException
from sqlalchemy import desc
from sqlalchemy.orm import Session

from app.algorithms.matching.taste_match import build_taste_vector, common_tags, cosine_similarity
from app.models.community import CommunityPost, PostComment, PostLike
from app.models.food_record import FoodRecord, FoodRecordItem
from app.models.taste import TasteVector
from app.models.user import User
from app.schemas.community import CommentCreate, PostCreate


class CommunityService:
    @staticmethod
    def create_post(db: Session, obj_in: PostCreate, user_id: int) -> CommunityPost:
        db_post = CommunityPost(
            user_id=user_id,
            title=obj_in.title,
            content=obj_in.content,
            food_record_id=obj_in.food_record_id,
            image_urls=obj_in.image_urls,
            tags=obj_in.tags,
            visibility=obj_in.visibility,
        )
        db.add(db_post)
        db.commit()
        db.refresh(db_post)
        return db_post

    @staticmethod
    def get_posts(db: Session, current_user_id: int, skip: int = 0, limit: int = 10) -> list:
        posts = (
            db.query(CommunityPost)
            .filter(CommunityPost.visibility == "public")
            .order_by(desc(CommunityPost.created_at))
            .offset(skip)
            .limit(limit)
            .all()
        )

        for post in posts:
            like = db.query(PostLike).filter_by(post_id=post.id, user_id=current_user_id).first()
            setattr(post, "is_liked", bool(like))

        return posts

    @staticmethod
    def get_post_by_id(db: Session, post_id: int) -> CommunityPost:
        post = db.query(CommunityPost).filter(CommunityPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="帖子不存在")
        return post

    @staticmethod
    def toggle_like(db: Session, post_id: int, user_id: int) -> dict:
        post = CommunityService.get_post_by_id(db, post_id)
        existing_like = db.query(PostLike).filter_by(post_id=post_id, user_id=user_id).first()

        if existing_like:
            db.delete(existing_like)
            post.like_count = max(0, post.like_count - 1)
            is_liked = False
        else:
            db.add(PostLike(post_id=post_id, user_id=user_id))
            post.like_count += 1
            is_liked = True

        db.commit()
        return {"post_id": post_id, "is_liked": is_liked, "like_count": post.like_count}

    @staticmethod
    def add_comment(db: Session, post_id: int, user_id: int, obj_in: CommentCreate) -> PostComment:
        post = CommunityService.get_post_by_id(db, post_id)
        new_comment = PostComment(post_id=post_id, user_id=user_id, content=obj_in.content)
        db.add(new_comment)
        post.comment_count += 1
        db.commit()
        db.refresh(new_comment)
        return new_comment

    @staticmethod
    def rebuild_taste_vector(db: Session, user_id: int) -> TasteVector:
        food_names = (
            db.query(FoodRecordItem.food_name)
            .join(FoodRecord, FoodRecordItem.food_record_id == FoodRecord.id)
            .filter(FoodRecord.user_id == user_id)
            .all()
        )
        vector, tags = build_taste_vector([row[0] for row in food_names])

        taste_vector = db.query(TasteVector).filter(TasteVector.user_id == user_id).first()
        if taste_vector is None:
            taste_vector = TasteVector(user_id=user_id)
            db.add(taste_vector)

        taste_vector.vector_json = vector
        taste_vector.tags = tags
        taste_vector.updated_source = "food_records"
        db.commit()
        db.refresh(taste_vector)
        return taste_vector

    @staticmethod
    def match_taste_buddies(
        db: Session,
        user_id: int,
        top_k: int = 5,
        prefer_same_goal: bool = True,
    ) -> dict:
        current_user = db.query(User).filter(User.id == user_id).first()
        current_vector = CommunityService.rebuild_taste_vector(db, user_id)
        if not current_vector.vector_json:
            current_vector.vector_json = [0.6, 0.5, 0.2, 0.7, 0.1, 0.1, 0.8, 0.3]
            current_vector.tags = ["高蛋白", "蔬菜友好", "清淡"]

        candidates = (
            db.query(TasteVector, User)
            .join(User, TasteVector.user_id == User.id)
            .filter(TasteVector.user_id != user_id)
            .all()
        )

        matches = []
        for taste_vector, user in candidates:
            similarity = cosine_similarity(current_vector.vector_json or [], taste_vector.vector_json or [])
            if prefer_same_goal and current_user and user.health_goal == current_user.health_goal:
                similarity = min(1.0, similarity + 0.05)
            matches.append({
                "user_id": user.id,
                "nickname": user.nickname or user.username,
                "avatar_url": user.avatar_url,
                "similarity": round(similarity, 4),
                "common_tags": common_tags(current_vector.tags or [], taste_vector.tags or []),
            })

        if not matches:
            matches = CommunityService._mock_taste_buddies()

        matches = sorted(matches, key=lambda item: item["similarity"], reverse=True)[:top_k]
        return {"matches": matches}

    @staticmethod
    def _mock_taste_buddies() -> list[dict]:
        return [
            {
                "user_id": 1002,
                "nickname": "低脂搭子",
                "avatar_url": None,
                "similarity": 0.87,
                "common_tags": ["高蛋白", "低脂"],
            },
            {
                "user_id": 1003,
                "nickname": "清淡饭友",
                "avatar_url": None,
                "similarity": 0.81,
                "common_tags": ["蔬菜友好", "清淡"],
            },
        ]
