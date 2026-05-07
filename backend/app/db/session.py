# backend/app/db/session.py

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

class DatabaseManager:
    """
    数据库连接管理器。
    
    作用：
    1. 负责创建与 PostgreSQL 的底层连接引擎 (Engine)。
    2. 配置连接池大小，防止高并发时数据库连接被撑爆。
    3. 提供 get_db_session 生成器，供 FastAPI 的 Depends() 依赖注入使用，
       确保每个 HTTP 请求都能获得一个独立的数据库会话，并在请求结束后自动关闭连接。
    """
    def __init__(self, db_url: str):
        # 创建数据库引擎
        # pool_pre_ping=True: 每次从连接池拿连接时，先“ping”一下，如果断开了就自动重连（防掉线神器）
        self.engine = create_engine(
            db_url,
            pool_pre_ping=True,
            pool_size=10,
            max_overflow=20
        )
        
        # 创建本地会话工厂
        self.SessionLocal = sessionmaker(
            autocommit=False, 
            autoflush=False, 
            bind=self.engine
        )

    def get_db_session(self):
        """
        依赖注入核心方法：获取数据库 Session
        """
        db = self.SessionLocal()
        try:
            yield db  # 将 session 交给请求使用
        finally:
            db.close()  # 请求结束，无论成功还是抛异常，必须释放连接回连接池