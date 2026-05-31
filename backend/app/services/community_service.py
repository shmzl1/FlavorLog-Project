from fastapi import HTTPException
from sqlalchemy import desc, or_
from sqlalchemy.orm import Session

from app.algorithms.matching.taste_match import build_taste_vector, common_tags, cosine_similarity
from app.models.community import (
    CommunityComment,
    CommunityCommentLike,
    CommunityPost,
    CommunityPostLike,
    CommunityShare,
)
from app.models.food_record import FoodRecord, FoodRecordItem
from app.models.taste import TasteVector
from app.models.user import User
from app.schemas.community import CommentCreate, PostCreate


class CommunityService:
    @staticmethod
    def _author_name(user: User | None) -> str:
        if user is None:
            return "知味志用户"
        return user.nickname or user.username or "知味志用户"

    @staticmethod
    def _post_to_dict(db: Session, post: CommunityPost, current_user_id: int) -> dict:
        user = db.query(User).filter(User.id == post.user_id).first()
        liked = (
            db.query(CommunityPostLike)
            .filter(
                CommunityPostLike.post_id == post.id,
                CommunityPostLike.user_id == current_user_id,
            )
            .first()
            is not None
        )
        return {
            "id": post.id,
            "user_id": post.user_id,
            "author_name": CommunityService._author_name(user),
            "title": post.title,
            "content": post.content,
            "food_record_id": post.food_record_id,
            "image_urls": post.image_urls or [],
            "tags": post.tags or [],
            "cover_url": post.cover_url,
            "source_type": post.source_type or "manual",
            "visibility": post.visibility or "public",
            "like_count": post.like_count or 0,
            "comment_count": post.comment_count or 0,
            "share_count": post.share_count or 0,
            "fork_count": post.fork_count or post.share_count or 0,
            "is_liked": liked,
            "created_at": post.created_at,
            "updated_at": post.updated_at,
        }

    @staticmethod
    def _comment_to_dict(db: Session, comment: CommunityComment, current_user_id: int) -> dict:
        user = db.query(User).filter(User.id == comment.user_id).first()
        liked = (
            db.query(CommunityCommentLike)
            .filter(
                CommunityCommentLike.comment_id == comment.id,
                CommunityCommentLike.user_id == current_user_id,
            )
            .first()
            is not None
        )
        return {
            "id": comment.id,
            "post_id": comment.post_id,
            "user_id": comment.user_id,
            "parent_id": comment.parent_id,
            "author_name": CommunityService._author_name(user),
            "content": comment.content,
            "like_count": comment.like_count or 0,
            "is_liked": liked,
            "created_at": comment.created_at,
            "updated_at": comment.updated_at,
            "replies": [],
        }

    @staticmethod
    def create_post(db: Session, obj_in: PostCreate, user_id: int) -> dict:
        title = obj_in.title.strip()
        if not title:
            raise HTTPException(status_code=400, detail="标题不能为空")
        db_post = CommunityPost(
            user_id=user_id,
            title=title,
            content=(obj_in.content or "").strip(),
            food_record_id=obj_in.food_record_id,
            image_urls=obj_in.image_urls,
            tags=obj_in.tags,
            cover_url=obj_in.cover_url,
            source_type=obj_in.source_type,
            visibility=obj_in.visibility,
        )
        db.add(db_post)
        db.commit()
        db.refresh(db_post)
        return CommunityService._post_to_dict(db, db_post, user_id)

    @staticmethod
    def get_posts(
        db: Session,
        current_user_id: int,
        skip: int = 0,
        limit: int = 10,
        keyword: str | None = None,
        tag: str | None = None,
        only_mine: bool = False,
    ) -> list[dict]:
        query = db.query(CommunityPost).filter(
            CommunityPost.visibility == "public",
            CommunityPost.is_deleted.is_(False),
        )
        if only_mine:
            query = query.filter(CommunityPost.user_id == current_user_id)
        if keyword:
            like_keyword = f"%{keyword}%"
            query = query.filter(or_(CommunityPost.title.ilike(like_keyword), CommunityPost.content.ilike(like_keyword)))
        if tag:
            query = query.filter(CommunityPost.tags.contains([tag]))

        posts = query.order_by(desc(CommunityPost.created_at)).offset(skip).limit(limit).all()
        return [CommunityService._post_to_dict(db, post, current_user_id) for post in posts]

    @staticmethod
    def get_post_by_id(db: Session, post_id: int) -> CommunityPost:
        post = (
            db.query(CommunityPost)
            .filter(CommunityPost.id == post_id, CommunityPost.is_deleted.is_(False))
            .first()
        )
        if not post:
            raise HTTPException(status_code=404, detail="帖子不存在")
        return post

    @staticmethod
    def get_post_detail(db: Session, post_id: int, current_user_id: int) -> dict:
        post = CommunityService.get_post_by_id(db, post_id)
        return CommunityService._post_to_dict(db, post, current_user_id)

    @staticmethod
    def toggle_like(db: Session, post_id: int, user_id: int) -> dict:
        post = CommunityService.get_post_by_id(db, post_id)
        existing_like = (
            db.query(CommunityPostLike)
            .filter(CommunityPostLike.post_id == post_id, CommunityPostLike.user_id == user_id)
            .first()
        )
        if existing_like:
            db.delete(existing_like)
            post.like_count = max(0, (post.like_count or 0) - 1)
            is_liked = False
        else:
            db.add(CommunityPostLike(post_id=post_id, user_id=user_id))
            post.like_count = (post.like_count or 0) + 1
            is_liked = True
        db.commit()
        return {"post_id": post_id, "is_liked": is_liked, "like_count": post.like_count}

    @staticmethod
    def share_post(db: Session, post_id: int, user_id: int, share_type: str = "fork") -> dict:
        post = CommunityService.get_post_by_id(db, post_id)
        normalized_type = (share_type or "fork").strip() or "fork"
        db.add(CommunityShare(post_id=post_id, user_id=user_id, share_type=normalized_type))
        post.share_count = (post.share_count or 0) + 1
        post.fork_count = max(post.fork_count or 0, post.share_count)
        db.commit()
        return {"post_id": post_id, "share_type": normalized_type, "share_count": post.share_count}

    @staticmethod
    def add_comment(db: Session, post_id: int, user_id: int, obj_in: CommentCreate) -> dict:
        post = CommunityService.get_post_by_id(db, post_id)
        content = obj_in.content.strip()
        if not content:
            raise HTTPException(status_code=400, detail="评论不能为空")
        if obj_in.parent_id:
            parent = (
                db.query(CommunityComment)
                .filter(
                    CommunityComment.id == obj_in.parent_id,
                    CommunityComment.post_id == post_id,
                    CommunityComment.is_deleted.is_(False),
                )
                .first()
            )
            if parent is None:
                raise HTTPException(status_code=404, detail="回复的评论不存在")

        new_comment = CommunityComment(
            post_id=post_id,
            user_id=user_id,
            parent_id=obj_in.parent_id,
            content=content,
        )
        db.add(new_comment)
        post.comment_count = (post.comment_count or 0) + 1
        db.commit()
        db.refresh(new_comment)
        return CommunityService._comment_to_dict(db, new_comment, user_id)

    @staticmethod
    def get_comments(db: Session, post_id: int, current_user_id: int, skip: int = 0, limit: int = 50) -> list[dict]:
        CommunityService.get_post_by_id(db, post_id)
        comments = (
            db.query(CommunityComment)
            .filter(CommunityComment.post_id == post_id, CommunityComment.is_deleted.is_(False))
            .order_by(CommunityComment.created_at.asc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        by_id = {
            comment.id: CommunityService._comment_to_dict(db, comment, current_user_id)
            for comment in comments
        }
        roots: list[dict] = []
        for comment in comments:
            item = by_id[comment.id]
            if comment.parent_id and comment.parent_id in by_id:
                by_id[comment.parent_id]["replies"].append(item)
            else:
                roots.append(item)
        return roots

    @staticmethod
    def toggle_comment_like(db: Session, comment_id: int, user_id: int) -> dict:
        comment = (
            db.query(CommunityComment)
            .filter(CommunityComment.id == comment_id, CommunityComment.is_deleted.is_(False))
            .first()
        )
        if not comment:
            raise HTTPException(status_code=404, detail="评论不存在")
        existing_like = (
            db.query(CommunityCommentLike)
            .filter(CommunityCommentLike.comment_id == comment_id, CommunityCommentLike.user_id == user_id)
            .first()
        )
        if existing_like:
            db.delete(existing_like)
            comment.like_count = max(0, (comment.like_count or 0) - 1)
            is_liked = False
        else:
            db.add(CommunityCommentLike(comment_id=comment_id, user_id=user_id))
            comment.like_count = (comment.like_count or 0) + 1
            is_liked = True
        db.commit()
        return {"comment_id": comment_id, "is_liked": is_liked, "like_count": comment.like_count}

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
    def match_taste_buddies(db: Session, user_id: int, top_k: int = 5, prefer_same_goal: bool = True) -> dict:
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
            matches.append(
                {
                    "user_id": user.id,
                    "nickname": user.nickname or user.username,
                    "avatar_url": user.avatar_url,
                    "similarity": round(similarity, 4),
                    "common_tags": common_tags(current_vector.tags or [], taste_vector.tags or []),
                }
            )

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
