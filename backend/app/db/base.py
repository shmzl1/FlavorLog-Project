# backend/app/db/base.py

from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    """
    SQLAlchemy 声明式基类。

    作用：
    这是整个 ORM（对象关系映射）系统的核心枢纽。项目里所有的数据库模型（如 User, FoodRecord）
    都必须继承这个类。当后端服务启动并配合 Alembic 迁移工具时，这个基类底层的元数据（metadata）
    会自动收集所有子类的表结构信息，从而将它们准确地同步到后端的 PostgreSQL 数据库中。
    """
    pass