from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.upload import UploadResponse
from app.services.upload_service import UploadService
from app.utils.response import success_response


router = APIRouter()


@router.post("/image", status_code=status.HTTP_200_OK)
async def upload_image(
    file: UploadFile = File(...),
    scene: str | None = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        saved = await UploadService.save(
            db, user_id=current_user.id, file=file, file_type="image", scene=scene
        )
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
    ).model_dump()
    return success_response(data=data)


@router.post("/video", status_code=status.HTTP_200_OK)
async def upload_video(
    file: UploadFile = File(...),
    scene: str | None = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        saved = await UploadService.save(
            db, user_id=current_user.id, file=file, file_type="video", scene=scene
        )
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
    ).model_dump()
    return success_response(data=data)


@router.post("/audio", status_code=status.HTTP_200_OK)
async def upload_audio(
    file: UploadFile = File(...),
    scene: str | None = Form(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    try:
        saved = await UploadService.save(
            db, user_id=current_user.id, file=file, file_type="audio", scene=scene
        )
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
    ).model_dump()
    return success_response(data=data)
