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
    ShareCreate,
    ShareResponse,
    TasteBuddyMatchRequest,
    TasteBuddyMatchResponse,
)
from app.schemas.response import StandardResponse, success_response
from app.services.community_service import CommunityService

router = APIRouter()


@router.get("/posts", response_model=StandardResponse[List[PostResponse]])
def get_posts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    keyword: str | None = None,
    tag: str | None = None,
    only_mine: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    posts = CommunityService.get_posts(
        db,
        current_user_id=current_user.id,
        skip=(page - 1) * page_size,
        limit=page_size,
        keyword=keyword,
        tag=tag,
        only_mine=only_mine,
    )
    return success_response(data=posts)


@router.post("/posts", response_model=StandardResponse[PostResponse])
def create_post(
    req: PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = CommunityService.create_post(db, obj_in=req, user_id=current_user.id)
    return success_response(data=post, msg="帖子发布成功")


@router.get("/posts/{post_id}", response_model=StandardResponse[PostResponse])
def get_post_detail(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    post = CommunityService.get_post_detail(db, post_id=post_id, current_user_id=current_user.id)
    return success_response(data=post)


@router.post("/posts/{post_id}/like", response_model=StandardResponse[LikeResponse])
def like_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = CommunityService.toggle_like(db, post_id=post_id, user_id=current_user.id)
    msg = "点赞成功" if result["is_liked"] else "已取消点赞"
    return success_response(data=result, msg=msg)


@router.post("/posts/{post_id}/share", response_model=StandardResponse[ShareResponse])
def share_post(
    post_id: int,
    req: ShareCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = CommunityService.share_post(
        db,
        post_id=post_id,
        user_id=current_user.id,
        share_type=req.share_type,
    )
    return success_response(data=result, msg="分享成功")


@router.get("/posts/{post_id}/comments", response_model=StandardResponse[List[CommentResponse]])
def get_comments(
    post_id: int,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comments = CommunityService.get_comments(
        db,
        post_id=post_id,
        current_user_id=current_user.id,
        skip=(page - 1) * page_size,
        limit=page_size,
    )
    return success_response(data=comments)


@router.post("/posts/{post_id}/comments", response_model=StandardResponse[CommentResponse])
def add_comment(
    post_id: int,
    req: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    comment = CommunityService.add_comment(db, post_id=post_id, user_id=current_user.id, obj_in=req)
    return success_response(data=comment, msg="评论发布成功")


@router.post("/comments/{comment_id}/like", response_model=StandardResponse[LikeResponse])
def like_comment(
    comment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = CommunityService.toggle_comment_like(db, comment_id=comment_id, user_id=current_user.id)
    msg = "评论点赞成功" if result["is_liked"] else "已取消评论点赞"
    return success_response(data=result, msg=msg)


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
