# backend/app/schemas/community.py

from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

# ==========================
# 1. 发帖相关
# ==========================
class PostCreate(BaseModel):
    title: str
    content: Optional[str] = None
    food_record_id: Optional[int] = None
    image_urls: List[str] = []
    tags: List[str] = []
    visibility: str = "public"

class PostResponse(BaseModel):
    id: int
    user_id: int
    title: str
    content: Optional[str]
    food_record_id: Optional[int]
    image_urls: List[str]
    tags: List[str]
    visibility: str
    like_count: int
    comment_count: int
    fork_count: int
    created_at: datetime
    # 额外附加字段，前端用来展示
    is_liked: bool = False 

    class Config:
        from_attributes = True

# ==========================
# 2. 评论相关
# ==========================
class CommentCreate(BaseModel):
    content: str

class CommentResponse(BaseModel):
    id: int
    post_id: int
    user_id: int
    content: str
    created_at: datetime

    class Config:
        from_attributes = True

# ==========================
# 3. 点赞相关
# ==========================
class LikeResponse(BaseModel):
    post_id: int
    is_liked: bool
    like_count: int