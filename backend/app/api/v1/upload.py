# backend/app/api/v1/upload.py

from fastapi import APIRouter, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.response import StandardResponse, success_response
from app.schemas.upload import UploadFileResponse
from app.services.upload_service import UploadService

router = APIRouter()

@router.post("/image", response_model=StandardResponse[UploadFileResponse])
def upload_image(
    file: UploadFile = File(...),
    scene: str = Form("food"), 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【上传】图片上传接口"""
    saved_file = UploadService.save_file(db, file=file, user_id=current_user.id, file_type="image", scene=scene)
    return success_response(data=saved_file, msg="图片上传成功")

@router.post("/video", response_model=StandardResponse[UploadFileResponse])
def upload_video(
    file: UploadFile = File(...),
    scene: str = Form("food_scan"), 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【上传】视频极速录入接口"""
    saved_file = UploadService.save_file(db, file=file, user_id=current_user.id, file_type="video", scene=scene)
    return success_response(data=saved_file, msg="视频上传成功")

@router.post("/audio", response_model=StandardResponse[UploadFileResponse])
def upload_audio(
    file: UploadFile = File(...),
    scene: str = Form("voice_note"), 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【上传】语音描述上传接口"""
    saved_file = UploadService.save_file(db, file=file, user_id=current_user.id, file_type="audio", scene=scene)
    return success_response(data=saved_file, msg="音频上传成功")