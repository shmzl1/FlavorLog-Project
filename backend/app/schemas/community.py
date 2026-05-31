from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


class PostCreate(BaseModel):
    title: str
    content: Optional[str] = None
    food_record_id: Optional[int] = None
    image_urls: List[str] = []
    tags: List[str] = []
    cover_url: Optional[str] = None
    source_type: str = "manual"
    visibility: str = "public"


class PostResponse(BaseModel):
    id: int
    user_id: int
    author_name: str = ""
    title: str
    content: Optional[str] = None
    food_record_id: Optional[int] = None
    image_urls: List[str] = []
    tags: List[str] = []
    cover_url: Optional[str] = None
    source_type: str = "manual"
    visibility: str = "public"
    like_count: int = 0
    comment_count: int = 0
    share_count: int = 0
    fork_count: int = 0
    is_liked: bool = False
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class CommentCreate(BaseModel):
    content: str
    parent_id: Optional[int] = None


class CommentResponse(BaseModel):
    id: int
    post_id: int
    user_id: int
    parent_id: Optional[int] = None
    author_name: str = ""
    content: str
    like_count: int = 0
    is_liked: bool = False
    created_at: datetime
    updated_at: Optional[datetime] = None
    replies: List["CommentResponse"] = []

    class Config:
        from_attributes = True


class LikeResponse(BaseModel):
    post_id: Optional[int] = None
    comment_id: Optional[int] = None
    is_liked: bool
    like_count: int


class ShareCreate(BaseModel):
    share_type: str = "fork"


class ShareResponse(BaseModel):
    post_id: int
    share_type: str
    share_count: int


class TasteBuddyMatchRequest(BaseModel):
    top_k: int = Field(5, ge=1, le=20)
    prefer_same_goal: bool = True


class TasteBuddyItem(BaseModel):
    user_id: int
    nickname: str
    avatar_url: Optional[str] = None
    similarity: float
    common_tags: List[str] = []


class TasteBuddyMatchResponse(BaseModel):
    matches: List[TasteBuddyItem]
