from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.security import token_generator
from app.models.user import User
from app.schemas.auth import AuthLoginRequest, AuthRegisterRequest
from app.schemas.user import UserCreate, UserResponse
from app.services.user_service import UserService
from app.utils.response import error_response, success_response


router = APIRouter()


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(payload: AuthRegisterRequest, db: Session = Depends(get_db)):
    if UserService.get_user_by_email(db, email=payload.email):
        raise HTTPException(status_code=400, detail="该邮箱已经被注册")
    if UserService.get_user_by_username(db, username=payload.username):
        raise HTTPException(status_code=400, detail="该用户名已经被占用")

    try:
        user_in = UserCreate(
            username=payload.username,
            email=payload.email,
            password=payload.password,
            nickname=payload.nickname,
        )
        user = UserService.create_user(db, user_in=user_in)
        access_token = token_generator.create_access_token(subject=user.id)
        data = {
            "user": UserResponse.model_validate(user).model_dump(),
            "access_token": access_token,
            "token_type": "bearer",
        }
        return success_response(data=data, message="success")
    except Exception as e:
        return error_response(code=50001, message=str(e))


@router.post("/login")
def login(payload: AuthLoginRequest, db: Session = Depends(get_db)):
    user = UserService.authenticate_user_by_account(db, account=payload.account, password=payload.password)
    if not user:
        raise HTTPException(status_code=401, detail="账号或密码错误")

    access_token = token_generator.create_access_token(subject=user.id)
    data = {
        "user": UserResponse.model_validate(user).model_dump(),
        "access_token": access_token,
        "token_type": "bearer",
    }
    return success_response(data=data, message="success")


@router.get("/me")
def me(current_user: User = Depends(get_current_user)):
    return success_response(data=UserResponse.model_validate(current_user).model_dump(), message="success")
