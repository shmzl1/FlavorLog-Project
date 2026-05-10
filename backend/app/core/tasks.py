# backend/app/core/tasks.py

import asyncio
from sqlalchemy.orm import Session
from app.core.redis import redis_client
# 💡 核心修改：改为导入 get_db
from app.api.deps import get_db
from app.models.community import CommunityPost as Post

async def sync_likes_to_db():
    """
    【定时任务】每隔 5 分钟，将 Redis 中的点赞数同步回 PostgreSQL
    """
    while True:
        try:
            # 1. 休息 300 秒 (5 分钟)
            # 调试阶段如果嫌 5 分钟太长，可以改成 10 (10秒) 来快速测试
            await asyncio.sleep(300)
            print("🕒 [后台任务] 正在执行点赞同步...")

            # 2. 获取 Redis 中所有的点赞计数的 Key (post:*:likes_count)
            keys = await redis_client.keys("post:*:likes_count") # type: ignore
            
            if not keys:
                continue

            # 3. 手动获取数据库连接
            db_gen = get_db()
            db: Session = next(db_gen)
            
            try:
                for key in keys:
                    # 从 key 名中提取 post_id (例如 "post:12:likes_count" -> 12)
                    post_id = int(key.split(":")[1])
                    
                    # 从 Redis 拿到最新点赞数
                    likes_count = await redis_client.get(key) # type: ignore
                    
                    if likes_count is not None:
                        # 4. 执行批量更新 PostgreSQL
                        db.query(Post).filter(Post.id == post_id).update({
                            "like_count": int(likes_count)
                        })
                
                # 提交数据库事务
                db.commit()
                print(f"✅ [后台任务] 成功同步 {len(keys)} 个帖子的点赞数据至数据库。")
            except Exception as e:
                db.rollback()
                print(f"❌ [后台任务] 数据库同步出错: {e}")
            finally:
                # 无论成功失败，必须安全关闭数据库连接 (触发 get_db() 生成器的结束)
                try:
                    next(db_gen)
                except StopIteration:
                    pass

        except Exception as e:
            print(f"❌ [后台任务] 遇到未知错误: {e}")