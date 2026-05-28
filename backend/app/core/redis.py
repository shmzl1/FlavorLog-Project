# backend/app/core/redis.py

import json
from typing import Any, Optional

from redis.asyncio import Redis  # type: ignore

from app.core.config import settings
from app.utils.logger import logger

redis_client: Redis = Redis.from_url(
    settings.REDIS_URL,
    decode_responses=True,
)


async def get_redis() -> Redis:
    return redis_client


def user_cache_key(user_id: int) -> str:
    """用户资料缓存 key。"""
    return f"flavorlog:user:{user_id}"


async def cache_get_json(key: str) -> Optional[dict[str, Any]]:
    """从 Redis 读取 JSON 对象。Redis 不可用时返回 None。"""
    if not settings.REDIS_ENABLED:
        return None

    try:
        raw_value = await redis_client.get(key)
        if not raw_value:
            return None
        return json.loads(raw_value)
    except Exception as e:
        logger.warning("Redis 读取缓存失败 key=%s error=%s", key, e)
        return None


async def cache_set_json(key: str, value: dict[str, Any], ttl_seconds: int | None = None) -> None:
    """写入 JSON 对象到 Redis。Redis 不可用时静默降级。"""
    if not settings.REDIS_ENABLED:
        return

    try:
        ttl = ttl_seconds or settings.USER_CACHE_TTL_SECONDS
        await redis_client.set(key, json.dumps(value, ensure_ascii=False), ex=ttl)
    except Exception as e:
        logger.warning("Redis 写入缓存失败 key=%s error=%s", key, e)


async def cache_delete(key: str) -> None:
    """删除指定缓存。Redis 不可用时静默降级。"""
    if not settings.REDIS_ENABLED:
        return

    try:
        await redis_client.delete(key)
    except Exception as e:
        logger.warning("Redis 删除缓存失败 key=%s error=%s", key, e)