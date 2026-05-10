from pydantic import BaseModel, Field
from typing import Optional

from app.schemas.user import UserResponse


class AuthLoginRequest(BaseModel):
    account: str = Field(..., description="用户名或邮箱")
    password: str


class AuthTokenData(BaseModel):
    user: UserResponse
    access_token: str
    token_type: str = "bearer"


class AuthRegisterRequest(BaseModel):
    username: str
    email: str
    password: str
    nickname: Optional[str] = None
