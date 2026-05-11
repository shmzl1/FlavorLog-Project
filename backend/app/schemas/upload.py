# backend/app/schemas/upload.py

from pydantic import BaseModel
from datetime import datetime

class UploadFileResponse(BaseModel):
    """
    文件上传成功后，返回给前端的数据结构。
    前端拿到 file_url 就可以直接在 App 里渲染图片了。
    """
    id: int
    file_name: str
    file_url: str      # 💡 核心字段：图片的访问链接，例如 /uploads/images/xxx.jpg
    file_type: str     # image, video, audio
    scene: str | None  # 场景：food, avatar 等
    created_at: datetime

    class Config:
        from_attributes = True