from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.community import (
    CommentCreate,
    CommentResponse,
    LikeResponse,
    PostCreate,
    PostResponse,
    TasteBuddyMatchRequest,
    TasteBuddyMatchResponse,
)
from app.schemas.response import StandardResponse, success_response
from app.services.community_service import CommunityService

router = APIRouter()


@router.post("/posts", response_model=StandardResponse[PostResponse])
def create_post(
    req: PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = CommunityService.create_post(db, obj_in=req, user_id=current_user.id)
    setattr(post, "is_liked", False)
    return success_response(data=post, msg="动态发布成功")


@router.get("/posts", response_model=StandardResponse[List[PostResponse]])
def get_posts(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    posts = CommunityService.get_posts(db, current_user_id=current_user.id, skip=skip, limit=limit)
    return success_response(data=posts)


@router.post("/posts/{post_id}/like", response_model=StandardResponse[LikeResponse])
def like_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = CommunityService.toggle_like(db, post_id=post_id, user_id=current_user.id)
    msg = "点赞成功" if result["is_liked"] else "已取消点赞"
    return success_response(data=result, msg=msg)


@router.post("/posts/{post_id}/comments", response_model=StandardResponse[CommentResponse])
def add_comment(
    post_id: int,
    req: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = CommunityService.add_comment(db, post_id=post_id, user_id=current_user.id, obj_in=req)
    return success_response(data=comment, msg="评论发布成功")


@router.post("/taste-buddies/match", response_model=StandardResponse[TasteBuddyMatchResponse])
def match_taste_buddies(
    req: TasteBuddyMatchRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    data = CommunityService.match_taste_buddies(
        db,
        user_id=current_user.id,
        top_k=req.top_k,
        prefer_same_goal=req.prefer_same_goal,
    )
    return success_response(data=data)
