from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.db.base import Base


class CommunityPost(Base):
    __tablename__ = "community_posts"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    food_record_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("food_records.id", ondelete="SET NULL"),
        nullable=True,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[Optional[str]] = mapped_column(Text)
    image_urls: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]", nullable=False)
    tags: Mapped[list] = mapped_column(JSONB, default=list, server_default="[]", nullable=False)
    cover_url: Mapped[Optional[str]] = mapped_column(Text)
    source_type: Mapped[str] = mapped_column(String(30), default="manual", server_default="manual")
    visibility: Mapped[str] = mapped_column(String(30), default="public", server_default="public")
    like_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0", nullable=False)
    comment_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0", nullable=False)
    share_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0", nullable=False)
    fork_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0", nullable=False)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, server_default="FALSE", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


class CommunityComment(Base):
    __tablename__ = "community_comments"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    post_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("community_posts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    parent_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("community_comments.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    content: Mapped[str] = mapped_column(Text, nullable=False)
    like_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0", nullable=False)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, server_default="FALSE", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


class CommunityPostLike(Base):
    __tablename__ = "community_post_likes"
    __table_args__ = (UniqueConstraint("post_id", "user_id", name="uq_community_post_likes_post_user"),)

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    post_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("community_posts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class CommunityCommentLike(Base):
    __tablename__ = "community_comment_likes"
    __table_args__ = (
        UniqueConstraint("comment_id", "user_id", name="uq_community_comment_likes_comment_user"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    comment_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("community_comments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class CommunityShare(Base):
    __tablename__ = "community_shares"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    post_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("community_posts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    share_type: Mapped[str] = mapped_column(String(30), default="fork", server_default="fork", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


# Backward-compatible aliases for older imports in scripts or tasks.
PostComment = CommunityComment
PostLike = CommunityPostLike
PostFork = CommunityShare
