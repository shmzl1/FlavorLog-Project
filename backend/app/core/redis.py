# backend/app/core/redis.py

import os
# 💡 明确导入 asyncio 下的 Redis 类
from redis.asyncio import Redis # type: ignore

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

# 💡 终极杀招：注意这里的 `: Redis`！
# 我们强行声明 redis_client 的类型就是异步的 Redis。
# 这样跨文件导入时，Pylance 就绝对不敢再把它当成同步对象了！
redis_client: Redis = Redis.from_url(REDIS_URL, decode_responses=True)

# 给函数也加上返回值注解，确保万无一失
async def get_redis() -> Redis:
    return redis_client