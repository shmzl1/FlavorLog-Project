# backend/app/core/security.py

from datetime import datetime, timedelta, timezone
from typing import Any, Union
from jose import jwt
from passlib.context import CryptContext
from app.core.config import settings

# ==========================================
# 密码哈希处理器配置
# ==========================================
# 指定使用 bcrypt 算法进行哈希。bcrypt 是一种自适应哈希算法，
# 能够有效抵御硬件加速的暴力破解攻击。
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class PasswordHasher:
    """
    用户密码安全处理类。

    职责：
    1. get_password_hash: 将用户注册时的明文密码转化为不可逆的 bcrypt 密文。
    2. verify_password: 在用户登录时，将输入的明文与库中密文比对，验证其合法性。
    """

    @staticmethod
    def verify_password(plain_password: str, hashed_password: str) -> bool:
        """
        验证明文密码与哈希密文是否匹配。

        Args:
            plain_password (str): 用户输入的原始明文。
            hashed_password (str): 数据库中存储的密文。

        Returns:
            bool: 匹配成功返回 True，否则返回 False。
        """
        return pwd_context.verify(plain_password, hashed_password)

    @staticmethod
    def get_password_hash(password: str) -> str:
        """
        生成安全的密码哈希。

        Args:
            password (str): 设置的原始明文。

        Returns:
            str: 用于存入数据库的哈希密文。
        """
        return pwd_context.hash(password)


class TokenGenerator:
    """
    JWT (JSON Web Token) 身份令牌生成类。

    职责：
    负责签发具有时效性的访问令牌（Access Token）。令牌签发后返回给前端（Flutter），
    前端后续的每一个需要权限的请求都会在 Header 中携带此令牌。
    采用 HS256 对称加密算法，安全性依赖于 .env 中的 JWT_SECRET_KEY。
    """

    @staticmethod
    def create_access_token(subject: Union[str, Any], expires_delta: timedelta = None) -> str: # type: ignore
        """
        签发 JWT 访问令牌。

        Args:
            subject (Union[str, Any]): 令牌的主体标识，通常存放用户 ID。
            expires_delta (timedelta, optional): 令牌有效期。默认使用配置中的 7 天。

        Returns:
            str: 加密后的 JWT 字符串。
        """
        if expires_delta:
            expire = datetime.now(timezone.utc) + expires_delta
        else:
            expire = datetime.now(timezone.utc) + timedelta(
                minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
            )
        
        # 定义 Payload 载荷
        to_encode = {"exp": expire, "sub": str(subject)}
        
        # 执行加密签名
        encoded_jwt = jwt.encode(
            to_encode, 
            settings.JWT_SECRET_KEY, 
            algorithm=settings.JWT_ALGORITHM
        )
        return encoded_jwt


# ==========================================
# 导出全局单例工具
# ==========================================
# 这样在 user_service.py 或 auth.py 中通过 
# `from app.core.security import pwd_hasher` 
# 就能直接使用了，不会再报错“未知符号”。
pwd_hasher = PasswordHasher()
token_generator = TokenGenerator()