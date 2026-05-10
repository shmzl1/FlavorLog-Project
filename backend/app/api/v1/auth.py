from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.core.security import token_generator
from app.models.user import User
from app.schemas.auth import AuthLoginRequest
from app.schemas.response import StandardResponse, success_response
from app.schemas.user import UserCreate, UserResponse
from app.services.user_service import UserService

router = APIRouter()


def _auth_payload(user: User) -> dict:
    return {
        "user": UserResponse.model_validate(user).model_dump(mode="json"),
        "access_token": token_generator.create_access_token(subject=user.id),
        "token_type": "bearer",
    }


@router.post("/register", response_model=StandardResponse, status_code=status.HTTP_201_CREATED)
def register_user(user_in: UserCreate, db: Session = Depends(get_db)):
    """用户注册，按接口文档返回用户信息和 access_token。"""
    if UserService.get_user_by_email(db, email=user_in.email):
        raise HTTPException(status_code=400, detail="该邮箱已经被注册")
    if UserService.get_user_by_username(db, username=user_in.username):
        raise HTTPException(status_code=400, detail="该用户名已经被注册")

    user = UserService.create_user(db, user_in=user_in)
    return success_response(data=_auth_payload(user), msg="账号注册成功")


@router.post("/login", response_model=StandardResponse)
def login_access_token(req: AuthLoginRequest, db: Session = Depends(get_db)):
    """用户登录，支持用户名或邮箱。"""
    user = UserService.authenticate_account(db, account=req.account, password=req.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="账号或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return success_response(data=_auth_payload(user), msg="登录成功")


@router.get("/me", response_model=StandardResponse[UserResponse])
def read_current_user(current_user: User = Depends(get_current_user)):
    """获取当前登录用户信息。"""
    return success_response(data=current_user)
