# backend/app/services/upload_service.py

import os
import uuid
import shutil
from datetime import datetime
from fastapi import UploadFile
from sqlalchemy.orm import Session

from app.models.upload_file import UploadFileModel

class UploadService:
    # 💡 升级点：根据文件类型，动态决定存到哪个文件夹
    @staticmethod
    def get_upload_dir(file_type: str) -> str:
        if file_type == "video":
            return "uploads/videos"
        elif file_type == "audio":
            return "uploads/audios"
        return "uploads/images" # 默认图片

    @staticmethod
    def save_file(db: Session, file: UploadFile, user_id: int, file_type: str = "image", scene: str = "default") -> UploadFileModel:
        """
        保存文件到硬盘，并记录到数据库。
        支持 image, video, audio
        """
        # 1. 动态获取目标文件夹并确保存在
        target_dir = UploadService.get_upload_dir(file_type)
        os.makedirs(target_dir, exist_ok=True)

        # 2. 安全提取文件名和后缀名
        safe_filename = file.filename or f"unknown.{file_type}"
        file_extension = safe_filename.split(".")[-1] if "." in safe_filename else "bin"

        # 3. 生成唯一文件名
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        unique_filename = f"{timestamp}_{uuid.uuid4().hex}.{file_extension}"
        
        # 4. 拼接物理路径
        file_path = os.path.join(target_dir, unique_filename)

        # 5. 存入硬盘
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # 6. 计算大小
        file.file.seek(0, 2)
        file_size = file.file.tell()
        file.file.seek(0)

        # 7. 写入数据库
        db_file = UploadFileModel(
            user_id=user_id,
            file_name=safe_filename,
            file_url=f"/{file_path}".replace("\\", "/"), # 修复 Windows 斜杠
            file_type=file_type, # 💡 动态记录是图片还是视频
            mime_type=file.content_type,
            size_bytes=file_size,
            scene=scene
        )
        db.add(db_file)
        db.commit()
        db.refresh(db_file)

        return db_file