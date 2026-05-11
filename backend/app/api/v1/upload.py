from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.response import StandardResponse, success_response
from app.schemas.upload import UploadResponse
from app.services.upload_service import UploadService


router = APIRouter()


@router.post(
    "/image",
    response_model=StandardResponse[UploadResponse],
    status_code=status.HTTP_200_OK,
    responses={400: {"description": "Bad Request"}},
)
def upload_image(
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    file: UploadFile = File(...),
    scene: str | None = Form(default=None),
):
    try:
        saved = UploadService.save_file(db, user_id=current_user.id, file=file, file_type="image", scene=scene)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    data = UploadResponse(
        file_id=saved.id,
        file_url=saved.file_url,
        file_name=saved.file_name,
        mime_type=saved.mime_type,
        size_bytes=saved.size_bytes,
        scene=saved.scene,
        created_at=saved.created_at,
    ).model_dump(mode="json")
    return success_response(data=data, msg="图片上传成功")


@router.post(
    "/video",
    response_model=StandardResponse[UploadResponse],
    status_code=status.HTTP_200_OK,
    responses={400: {"description": "Bad Request"}},
)
def upload_video(
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    file: UploadFile = File(...),
    scene: str | None = Form(default=None),
):
    try:
        saved = UploadService.save_file(db, user_id=current_user.id, file=file, file_type="video", scene=scene)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    data = UploadResponse(
        file_id=saved.id,
        file_url=saved.file_url,
        file_name=saved.file_name,
        mime_type=saved.mime_type,
        size_bytes=saved.size_bytes,
        scene=saved.scene,
        created_at=saved.created_at,
    ).model_dump(mode="json")
    return success_response(data=data, msg="视频上传成功")


@router.post(
    "/audio",
    response_model=StandardResponse[UploadResponse],
    status_code=status.HTTP_200_OK,
    responses={400: {"description": "Bad Request"}},
)
def upload_audio(
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    file: UploadFile = File(...),
    scene: str | None = Form(default=None),
):
    try:
        saved = UploadService.save_file(db, user_id=current_user.id, file=file, file_type="audio", scene=scene)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    data = UploadResponse(
        file_id=saved.id,
        file_url=saved.file_url,
        file_name=saved.file_name,
        mime_type=saved.mime_type,
        size_bytes=saved.size_bytes,
        scene=saved.scene,
        created_at=saved.created_at,
    ).model_dump(mode="json")
    return success_response(data=data, msg="音频上传成功")
