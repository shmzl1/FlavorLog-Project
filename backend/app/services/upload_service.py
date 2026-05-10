import os
from datetime import datetime
from uuid import uuid4

from fastapi import UploadFile
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.upload import UploadFile as UploadFileModel


class UploadService:
    @staticmethod
    def _ensure_dir(path: str) -> None:
        os.makedirs(path, exist_ok=True)

    @staticmethod
    def _safe_ext(filename: str) -> str:
        _, ext = os.path.splitext(filename or "")
        ext = ext.lower().strip()
        if ext and len(ext) <= 10:
            return ext
        return ""

    @staticmethod
    def _new_filename(original: str) -> str:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        ext = UploadService._safe_ext(original)
        return f"{ts}_{uuid4().hex[:10]}{ext}"

    @staticmethod
    async def save(
        db: Session,
        *,
        user_id: int,
        file: UploadFile,
        file_type: str,
        scene: str | None,
    ) -> UploadFileModel:
        file_type = file_type.lower()
        if file_type == "image":
            rel_dir = settings.IMAGE_UPLOAD_DIR
            max_mb = settings.MAX_IMAGE_SIZE_MB
        elif file_type == "video":
            rel_dir = settings.VIDEO_UPLOAD_DIR
            max_mb = settings.MAX_VIDEO_SIZE_MB
        elif file_type == "audio":
            rel_dir = settings.AUDIO_UPLOAD_DIR
            max_mb = settings.MAX_AUDIO_SIZE_MB
        else:
            raise ValueError("unsupported file_type")

        backend_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        abs_dir = os.path.join(backend_root, rel_dir)
        UploadService._ensure_dir(abs_dir)

        name = UploadService._new_filename(file.filename or file_type)
        abs_path = os.path.join(abs_dir, name)

        content = await file.read()
        size_bytes = len(content)
        if size_bytes > int(max_mb) * 1024 * 1024:
            raise ValueError("file too large")

        with open(abs_path, "wb") as f:
            f.write(content)

        file_url = f"/uploads/{os.path.basename(rel_dir)}/{name}"
        db_obj = UploadFileModel(
            user_id=user_id,
            file_name=name,
            file_url=file_url,
            file_type=file_type,
            mime_type=file.content_type,
            size_bytes=size_bytes,
            scene=scene,
            meta_json={},
        )
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def get_by_id(db: Session, *, user_id: int, file_id: int) -> UploadFileModel | None:
        return (
            db.query(UploadFileModel)
            .filter(UploadFileModel.id == file_id, UploadFileModel.user_id == user_id)
            .first()
        )
