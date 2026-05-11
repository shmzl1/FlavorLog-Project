# backend/app/api/deps.py

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import DatabaseManager
from app.models.user import User

# 1. 实例化全局数据库连接池管理器
# 以后所有的接口都从这里拿数据库连接，保证高并发性能
db_manager = DatabaseManager(settings.DATABASE_URL)

def get_db():
    """获取数据库 Session 的生成器"""
    yield from db_manager.get_db_session()

# 2. 声明 OAuth2 的 Token 获取机制
# tokenUrl 告诉 Swagger UI 去哪个接口获取 Token 才能出现那个绿色的 Authorize 锁头按钮
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_PREFIX}/users/login")

def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
) -> User:
    """
    全局安全保安：解析 Token 并获取当前登录用户。
    
    作用：
    挂载到任何需要权限的接口上。如果没有 Token 或 Token 伪造/过期，
    直接抛出 401 拦截请求，根本不会进入业务代码。
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="无法验证凭证 (Token无效、被篡改或已过期)",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        # 使用你 .env 里的私钥解密 Token
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        
        # 提取我们在 security.py 里塞进去的 subject (用户 ID)
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
            
    except JWTError:
        raise credentials_exception

    # 拿着解析出来的 ID 去数据库里查有没有这个人
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception

    return user