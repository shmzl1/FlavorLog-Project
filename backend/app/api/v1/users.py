# backend/app/api/v1/users.py

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

# 导入 Schema、Service 和 Token 工具类
from app.schemas.user import UserCreate, UserResponse
from app.schemas.token import Token
from app.services.user_service import UserService
from app.core.security import token_generator

# 💡 导入全局依赖：数据库连接生成器 和 我们的“保安”函数
from app.api.deps import get_db, get_current_user
from app.models.user import User

# 创建路由组
router = APIRouter()

# ==========================================
# 1. 用户注册接口
# ==========================================
@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    用户注册接口。
    """
    # 检查邮箱是否冲突
    existing_user = UserService.get_user_by_email(db, email=user_in.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该邮箱已经被注册，请更换邮箱或前往登录页面。"
        )
    
    # 执行入库
    new_user = UserService.create_user(db, user_in=user_in)
    return new_user


# ==========================================
# 2. 用户登录接口 (发牌)
# ==========================================
@router.post("/login", response_model=Token)
def login_access_token(
    db: Session = Depends(get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    """
    用户登录接口 (OAuth2 标准兼容)。
    通过账号密码换取 JWT Token。
    """
    # 去 Service 层比对账号和加密密码
    user = UserService.authenticate_user(
        db, email=form_data.username, password=form_data.password
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="邮箱或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # 验证通过，用用户的 ID 签发 JWT Token
    access_token = token_generator.create_access_token(subject=user.id)
    
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


# ==========================================
# 3. 获取当前登录用户信息 (保安测试)
# ==========================================
@router.get("/me", response_model=UserResponse)
def read_current_user(current_user: User = Depends(get_current_user)):
    """
    获取当前登录用户信息。
    
    重点：只要在参数里加上 `Depends(get_current_user)`，
    这个接口就变成了“受保护的私密接口”。没有 Token 绝对进不来！
    """
    # current_user 已经是我们的保安从数据库里查出来并验明正身的用户对象了，直接返回即可
    return current_user