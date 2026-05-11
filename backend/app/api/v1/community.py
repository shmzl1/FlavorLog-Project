import json
from typing import List

from fastapi import APIRouter, Depends, Query
from fastapi.concurrency import run_in_threadpool
from fastapi.encoders import jsonable_encoder
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.redis import redis_client
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
    """【社区】发布社区动态"""
    post = CommunityService.create_post(db, obj_in=req, user_id=current_user.id)
    setattr(post, "is_liked", False)
    return success_response(data=post, msg="动态发布成功")


@router.get("/posts", response_model=StandardResponse[List[PostResponse]])
async def get_posts(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """【社区】获取社区动态列表"""
    cache_key = f"cache:posts:global:s_{skip}:l_{limit}"

    try:
        cached = await redis_client.get(cache_key)  # type: ignore
        if cached:
            return success_response(data=json.loads(cached))
    except Exception as exc:
        print(f"Redis 读取异常: {exc}")

    posts = await run_in_threadpool(
        CommunityService.get_posts,
        db,
        current_user_id=current_user.id,
        skip=skip,
        limit=limit,
    )

    try:
        await redis_client.setex(cache_key, 60, json.dumps(jsonable_encoder(posts)))  # type: ignore
    except Exception:
        pass

    return success_response(data=posts)


@router.post("/posts/{post_id}/like", response_model=StandardResponse[LikeResponse])
async def like_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """【社区】点赞 / 取消点赞动态"""
    user_liked_key = f"post:{post_id}:liked_users"
    count_key = f"post:{post_id}:likes_count"

    try:
        already_liked = await redis_client.sismember(user_liked_key, current_user.id)  # type: ignore

        if already_liked:
            await redis_client.srem(user_liked_key, current_user.id)  # type: ignore
            await redis_client.decr(count_key)  # type: ignore
            is_liked = False
        else:
            await redis_client.sadd(user_liked_key, current_user.id)  # type: ignore
            await redis_client.incr(count_key)  # type: ignore
            is_liked = True

        likes_val = await redis_client.get(count_key)  # type: ignore
        likes_count = max(0, int(likes_val) if likes_val else 0)

        result = {
            "post_id": post_id,
            "is_liked": is_liked,
            "like_count": likes_count,
        }
        return success_response(data=result, msg="点赞成功" if is_liked else "已取消点赞")
    except Exception as exc:
        print(f"Redis 点赞失败，回退数据库: {exc}")
        result = await run_in_threadpool(
            CommunityService.toggle_like,
            db,
            post_id=post_id,
            user_id=current_user.id,
        )
        formatted_result = {
            "post_id": post_id,
            "is_liked": result.get("is_liked"),
            "like_count": result.get("like_count") or result.get("likes_count", 0),
        }
        msg = "点赞成功" if formatted_result["is_liked"] else "已取消点赞"
        return success_response(data=formatted_result, msg=msg)


@router.post("/posts/{post_id}/comments", response_model=StandardResponse[CommentResponse])
def add_comment(
    post_id: int,
    req: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """【社区】评论动态"""
    comment = CommunityService.add_comment(db, post_id=post_id, user_id=current_user.id, obj_in=req)
    return success_response(data=comment, msg="评论发布成功")


@router.post("/taste-buddies/match", response_model=StandardResponse[TasteBuddyMatchResponse])
def match_taste_buddies(
    req: TasteBuddyMatchRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """【社区】寻找口味搭子"""
    data = CommunityService.match_taste_buddies(
        db,
        user_id=current_user.id,
        top_k=req.top_k,
        prefer_same_goal=req.prefer_same_goal,
    )
    return success_response(data=data)
