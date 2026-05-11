from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class UploadResponse(BaseModel):
    file_id: int
    file_url: str
    file_name: str
    mime_type: Optional[str] = None
    size_bytes: int
    scene: Optional[str] = None
    created_at: Optional[datetime] = None
