# backend/app/services/community_service.py

from sqlalchemy.orm import Session
from sqlalchemy import desc
from fastapi import HTTPException

# 引入之前写好的数据库模型
from app.models.community import CommunityPost, PostLike, PostComment
from app.schemas.community import PostCreate, CommentCreate

class CommunityService:

    # ---------------- 发帖 & 查询 ----------------
    @staticmethod
    def create_post(db: Session, obj_in: PostCreate, user_id: int) -> CommunityPost:
        db_post = CommunityPost(
            user_id=user_id,
            title=obj_in.title,
            content=obj_in.content,
            food_record_id=obj_in.food_record_id,
            image_urls=obj_in.image_urls,
            tags=obj_in.tags,
            visibility=obj_in.visibility
        )
        db.add(db_post)
        db.commit()
        db.refresh(db_post)
        return db_post

    @staticmethod
    def get_posts(db: Session, current_user_id: int, skip: int = 0, limit: int = 10) -> list:
        # 按时间倒序查询公开帖子
        posts = db.query(CommunityPost).filter(CommunityPost.visibility == 'public')\
                  .order_by(desc(CommunityPost.created_at)).offset(skip).limit(limit).all()
        
        # 判断当前用户是否点赞了这些帖子
        for post in posts:
            like = db.query(PostLike).filter_by(post_id=post.id, user_id=current_user_id).first()
            # 💡 修复：使用 setattr 动态绑定属性，绕过 Pylance 检查
            setattr(post, "is_liked", True if like else False)
            
        return posts

    @staticmethod
    def get_post_by_id(db: Session, post_id: int) -> CommunityPost:
        post = db.query(CommunityPost).filter(CommunityPost.id == post_id).first()
        if not post:
            raise HTTPException(status_code=404, detail="帖子不存在")
        return post

    # ---------------- 点赞功能 ----------------
    @staticmethod
    def toggle_like(db: Session, post_id: int, user_id: int) -> dict:
        post = CommunityService.get_post_by_id(db, post_id)
        
        # 查找是否已经点赞过
        existing_like = db.query(PostLike).filter_by(post_id=post_id, user_id=user_id).first()
        
        if existing_like:
            # 取消点赞
            db.delete(existing_like)
            post.like_count = max(0, post.like_count - 1)
            is_liked = False
        else:
            # 新增点赞
            new_like = PostLike(post_id=post_id, user_id=user_id)
            db.add(new_like)
            post.like_count += 1
            is_liked = True
            
        db.commit()
        return {"post_id": post_id, "is_liked": is_liked, "like_count": post.like_count}

    # ---------------- 评论功能 ----------------
    @staticmethod
    def add_comment(db: Session, post_id: int, user_id: int, obj_in: CommentCreate) -> PostComment:
        post = CommunityService.get_post_by_id(db, post_id)
        
        new_comment = PostComment(
            post_id=post_id,
            user_id=user_id,
            content=obj_in.content
        )
        db.add(new_comment)
        
        # 更新帖子的评论数
        post.comment_count += 1
        db.commit()
        db.refresh(new_comment)
        return new_comment