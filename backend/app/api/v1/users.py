# backend/app/api/v1/users.py

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

# 💡 导入统一响应格式工具
from app.schemas.response import StandardResponse, success_response
# 导入 Schema、Service 和 Token 工具类
from app.schemas.user import UserCreate, UserResponse, UserUpdate
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
@router.post("/register", response_model=StandardResponse[UserResponse], status_code=status.HTTP_201_CREATED)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    """
    用户注册接口。
    已适配 StandardResponse 统一返回格式。
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
    
    # 💡 使用 success_response 进行包裹
    return success_response(data=new_user, msg="账号注册成功")


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
    
    ⚠️ 注意：此接口保持原有的 Token 格式返回，不使用 StandardResponse 包裹。
    这是为了兼容 Swagger UI 自带的 'Authorize' 锁定功能，
    因为该功能强制要求返回体必须直接包含 access_token 字段。
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
# 3. 获取当前登录用户信息
# ==========================================
@router.get("/me", response_model=StandardResponse[UserResponse])
def read_current_user(current_user: User = Depends(get_current_user)):
    """
    获取当前登录用户信息。
    """
    # current_user 已经是保安验证过的对象，直接包裹返回
    return success_response(data=current_user)


# ==========================================
# 4. 修改/完善个人资料 (软柿子一号)
# ==========================================
@router.put("/me", response_model=StandardResponse[UserResponse])
def update_user_me(
    obj_in: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    完善/修改个人资料。
    支持修改：昵称、性别、身高、体重、健康目标、饮食偏好、过敏源。
    """
    updated_user = UserService.update_user(db, db_user=current_user, obj_in=obj_in)
    
    return success_response(data=updated_user, msg="个人资料已更新")