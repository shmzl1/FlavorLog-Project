# backend/app/services/user_service.py

from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.security import pwd_hasher

class UserService:
    """
    用户领域核心业务逻辑类。

    作用：
    作为 Controller (API 路由) 和 Repository (数据库模型) 之间的桥梁。
    封装了所有与用户紧密相关的复杂业务操作（如创建用户、查询用户）。
    将这层逻辑剥离出来，不仅让 API 路由层变得非常薄，也极大方便了后续编写针对核心逻辑的单元测试。
    """

    @staticmethod
    def get_user_by_email(db: Session, email: str) -> User | None:
        """
        根据邮箱精准查询用户。

        作用：
        这是一个非常高频的读取操作，通常用于注册前的唯一性冲突检查，
        或者登录时的账号查找。

        Args:
            db (Session): SQLAlchemy 的数据库会话实例。
            email (str): 待查询的用户邮箱。

        Returns:
            User | None: 如果查到则返回 User 的 ORM 对象，否则返回 None。
        """
        return db.query(User).filter(User.email == email).first()

    @staticmethod
    def create_user(db: Session, user_in: UserCreate) -> User:
        """
        执行用户注册的核心创建逻辑。

        作用：
        接收经过 Pydantic 校验的注册请求体，剥离出明文密码进行单向哈希加密。
        随后构建 User ORM 对象，将其挂载到当前数据库事务中，并提交落盘。

        内部流程：
        1. 读取明文密码 -> 2. 生成密文 -> 3. 创建 ORM 对象 -> 4. 提交事务 -> 5. 刷新返回结果

        Args:
            db (Session): 负责控制数据库事务的会话实例。
            user_in (UserCreate): 包含合法注册信息（username, email, password 等）的 Pydantic 模型。

        Returns:
            User: 已经成功写入数据库，并带有最新主键 ID 的用户 ORM 对象。
        """
        # 1. 提取并加密密码
        hashed_pwd = pwd_hasher.get_password_hash(user_in.password)
        
        # 2. 构建数据库 ORM 对象 (注意这里丢弃了原始的明文 password)
        db_user = User(
            username=user_in.username,
            email=user_in.email,
            password_hash=hashed_pwd,
            #is_active=user_in.is_active
        )
        
        # 3. 将对象添加到当前会话
        db.add(db_user)
        
        # 4. 提交事务，真正将数据写入 PostgreSQL
        db.commit()
        
        # 5. 刷新对象，确保 db_user 获取到数据库自动生成的 id 和 created_at 等字段
        db.refresh(db_user)
        
        return db_user
    
    @staticmethod
    def authenticate_user(db: Session, email: str, password: str) -> User | None:
        """
        验证用户登录。
        1. 先根据邮箱找到用户。
        2. 如果用户存在，再验证明文密码与数据库里的密文是否匹配。
        """
        user = UserService.get_user_by_email(db, email=email)
        if not user:
            return None
        
        # 使用我们之前在 security.py 写的 verify_password 方法比对哈希
        if not pwd_hasher.verify_password(password, user.password_hash):
            return None
            
        return user