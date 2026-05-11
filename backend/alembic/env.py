# backend/alembic/env.py

import os
import sys
from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool
from alembic import context

# ==========================================
# 1. 动态路径修复 (架构级必备)
# ==========================================
# 作用：获取当前 env.py 的物理路径，并向上一层推送到 backend 目录。
# 这样即便从不同的终端路径运行 alembic 命令，系统也能准确识别 'app' 模块。
current_dir = os.path.dirname(os.path.realpath(__file__))
backend_dir = os.path.realpath(os.path.join(current_dir, '..'))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

# ==========================================
# 2. 全局配置与元数据导入
# ==========================================
from app.core.config import settings
from app.db.base import Base

# ⚠️ 关键操作：在此处显式导入所有 ORM 模型类
# 作用说明：
# Alembic 的 --autogenerate 功能依赖于 Base.metadata。
# 只有在这里被 import 过的 Python 类，其对应的表结构才会被注册到元数据中。
# 如果不在这里 import，Alembic 会误认为这些表在代码里不存在，
# 从而在迁移脚本中生成 'drop_table' 语句，导致刚才你遇到的外键依赖删除错误。
from app.models.user import User
from app.models.food_record import FoodRecord, FoodRecordItem
from app.models.fridge_item import FridgeItem
from app.models.community import CommunityPost, PostComment, PostLike, PostFork
from app.models.health import HealthFeedback
from app.models.ai_task import AITask, AIAnalysisLog, RecipeRecommendation
from app.models.upload import UploadFile
from app.models.taste import TasteVector
# 如果后续增加了 UploadFile 等新模型，请务必继续在此处添加 import

# ==========================================
# 3. Alembic 标准初始化
# ==========================================
# config 对象提供对 alembic.ini 文件中配置项的访问
config = context.config

# 配置 Python 运行时的日志输出格式
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# 绑定元数据：让 Alembic 知道“理想状态”的表结构应该是怎样的
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """
    运行“离线模式”迁移。

    业务场景：
    当环境不允许直接连接数据库（如安全审计），或仅需要获取 SQL 变更脚本时使用。
    该函数会从 settings 中读取 URL，并将变更以 SQL 文本形式打印到控制台。
    """
    url = settings.DATABASE_URL
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """
    运行“在线模式”迁移（最常用）。

    业务逻辑：
    1. 动态抓取 settings.DATABASE_URL 覆盖 alembic.ini 中的占位符。
    2. 建立与 PostgreSQL 的真实连接池。
    3. 在一个隔离的事务中执行表结构变更，确保变更的原子性（要么全成功，要么全回滚）。
    """
    # 动态注入 .env 中的数据库连接串，确保多环境切换的灵活性
    configuration = config.get_section(config.config_ini_section)
    if configuration is None:
        configuration = {}
    configuration['sqlalchemy.url'] = settings.DATABASE_URL

    # 创建物理连接引擎
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection, 
            target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


# ==========================================
# 4. 执行入口
# ==========================================
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()