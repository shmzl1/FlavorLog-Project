# backend/app/schemas/token.py

from pydantic import BaseModel

class Token(BaseModel):
    """
    返回给前端的 Token 模型。
    符合 OAuth2 标准规范。
    """
    access_token: str
    token_type: str = "bearer"