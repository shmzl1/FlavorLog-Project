# backend/app/services/auth_service.py

from sqlalchemy.orm import Session
from app.services.user_service import UserService
from app.core.security import pwd_hasher

class AuthService:
    """
    身份认证核心服务类。

    作用：
    本类封装了“登录验证”的原子逻辑。它会调用 UserService 查库获取用户信息，
    并利用 PasswordHasher 对用户输入的明文密码与库中的密文进行暴力破解防御级的校验。
    如果验证通过，它将确认该用户为合法身份。
    """

    @staticmethod
    def authenticate(db: Session, email: str, password: str):
        """
        执行账号密码的双重匹配验证。

        Args:
            db (Session): 数据库会话。
            email (str): 用户输入的登录邮箱。
            password (str): 用户输入的明文密码。

        Returns:
            User | None: 验证成功返回 User 对象，失败则返回 None。
        """
        # 1. 查找用户是否存在
        user = UserService.get_user_by_email(db, email=email)
        if not user:
            return None
        
        # 2. 校验密码哈希是否匹配
        # 注意：user.password_hash 对应 init.sql 中定义的字段名
        if not pwd_hasher.verify_password(password, user.password_hash): # type: ignore
            return None
        
        return user