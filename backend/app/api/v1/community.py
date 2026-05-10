# backend/app/api/v1/community.py

import json
from typing import List
from fastapi import APIRouter, Depends, Query, HTTPException
from fastapi.encoders import jsonable_encoder
from fastapi.concurrency import run_in_threadpool
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.response import StandardResponse, success_response

# 💡 注意：如果 Pylance 提示 PostCreate 是 module，请检查此处导入路径
from app.schemas.community import PostCreate, PostResponse, CommentCreate, CommentResponse, LikeResponse
from app.services.community_service import CommunityService

# 💡 引入 Redis 客户端
from app.core.redis import redis_client

router = APIRouter()

@router.post("/posts", response_model=StandardResponse[PostResponse])
def create_post(
    req: PostCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【社区】发布社区动态"""
    post = CommunityService.create_post(db, obj_in=req, user_id=current_user.id)
    # 刚发布的帖子默认没有被点赞
    setattr(post, "is_liked", False)
    return success_response(data=post, msg="动态发布成功")


# ==========================================
# 🚀 高并发改造：增加 Redis 缓存
# ==========================================
@router.get("/posts", response_model=StandardResponse[List[PostResponse]])
async def get_posts(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【社区】获取社区动态列表"""
    # 构造唯一的缓存 Key
    cache_key = f"cache:posts:u_{current_user.id}:s_{skip}:l_{limit}"
    
    try:
        # 1. 尝试从缓存获取
        cached = await redis_client.get(cache_key) # type: ignore
        if cached:
            print("⚡ Redis 缓存命中")
            return success_response(data=json.loads(cached))
    except Exception as e:
        print(f"Redis 读取异常: {e}")

    # 2. 缓存未命中，跑原本的 Service 逻辑
    posts = await run_in_threadpool(
        CommunityService.get_posts, db, current_user_id=current_user.id, skip=skip, limit=limit
    )
    
    # 3. 异步写入缓存，设置 60 秒有效期
    try:
        await redis_client.setex(cache_key, 60, json.dumps(jsonable_encoder(posts))) # type: ignore
    except:
        pass

    return success_response(data=posts)


# ==========================================
# 🚀 高并发改造：基于 Redis 的秒级点赞
# ==========================================
@router.post("/posts/{post_id}/like", response_model=StandardResponse[LikeResponse])
async def like_post(
    post_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【社区】点赞 / 取消点赞动态 (Redis 高并发版)"""
    user_liked_key = f"post:{post_id}:liked_users"
    count_key = f"post:{post_id}:likes_count"

    try:
        # 1. 判断是否已点赞 (使用 # type: ignore 压制 Pylance 误报)
        already_liked = await redis_client.sismember(user_liked_key, current_user.id) # type: ignore
        
        if already_liked:
            # 取消点赞
            await redis_client.srem(user_liked_key, current_user.id) # type: ignore
            await redis_client.decr(count_key) # type: ignore
            is_liked = False
        else:
            # 执行点赞
            await redis_client.sadd(user_liked_key, current_user.id) # type: ignore
            await redis_client.incr(count_key) # type: ignore
            is_liked = True

        # 2. 获取最新点赞数
        likes_val = await redis_client.get(count_key) # type: ignore
        likes_count = max(0, int(likes_val) if likes_val else 0)

        # ✅ 核心修复：严格对齐 LikeResponse 的字段名 (post_id, is_liked, like_count)
        # 解决之前的 ResponseValidationError 错误
        result = {
            "post_id": post_id,
            "is_liked": is_liked,
            "like_count": likes_count
        }

        return success_response(
            data=result,
            msg="点赞成功" if is_liked else "已取消点赞"
        )
    except Exception as e:
        # 降级方案：Redis 异常时回退到数据库逻辑
        print(f"Redis 点赞失败，回退数据库: {e}")
        result = await run_in_threadpool(
            CommunityService.toggle_like, db, post_id=post_id, user_id=current_user.id
        )
        # 注意：这里也要确保 Service 返回的字典字段名和 LikeResponse 匹配
        # 如果 Service 返回的是旧格式，建议在这里手动转换一下
        formatted_result = {
            "post_id": post_id,
            "is_liked": result.get("is_liked"),
            "like_count": result.get("like_count") or result.get("likes_count", 0)
        }
        msg = "点赞成功" if formatted_result["is_liked"] else "已取消点赞"
        return success_response(data=formatted_result, msg=msg)


@router.post("/posts/{post_id}/comments", response_model=StandardResponse[CommentResponse])
def add_comment(
    post_id: int,
    req: CommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【社区】评论动态"""
    comment = CommunityService.add_comment(db, post_id=post_id, user_id=current_user.id, obj_in=req)
    return success_response(data=comment, msg="评论发布成功")