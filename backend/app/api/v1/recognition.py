# backend/app/api/v1/recognition.py

import os
import shutil
import cv2
import numpy as np
from typing import List
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.food_record import FoodRecordCreate, FoodRecord
from app.schemas.response import StandardResponse, success_response # 💡 保持一致性
from app.services.video_entry_service import VideoEntryService
from app.services.food_record_service import FoodRecordService
from app.algorithms.vision.yolo_detector import YoloFoodDetector
from app.algorithms.llm.standardizer import RecordStandardizer

router = APIRouter()

# 实例化
video_entry_service = VideoEntryService()
yolo_detector = YoloFoodDetector(model_path="models/yolov8n.pt")
standardizer = RecordStandardizer()
food_record_service = FoodRecordService()

@router.post("/photo", response_model=StandardResponse[FoodRecordCreate])
async def recognize_photo_to_draft(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="请上传有效的图片文件")

    image_bytes = await file.read()
    nparr = np.frombuffer(image_bytes, np.uint8)
    image_cv2 = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if image_cv2 is None:
        raise HTTPException(status_code=400, detail="图片解码失败")

    yolo_result = yolo_detector.detect_image(image_cv2)
    if not yolo_result.get("foods"):
        raise HTTPException(status_code=404, detail="未识别到食物")

    draft = standardizer.ai_result_to_food_record(yolo_result)
    draft.source_type = "photo_ai"
    
    return success_response(data=draft, msg="识别成功")

@router.post("/video-fast-entry", response_model=StandardResponse[List[FoodRecordCreate]])
async def recognize_video_to_drafts(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    if not file.content_type or not file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="请上传有效的视频文件")

    temp_dir = "/tmp/video_uploads"
    os.makedirs(temp_dir, exist_ok=True)
    temp_video_path = os.path.join(temp_dir, f"{file.filename}")

    try:
        with open(temp_video_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        draft_records = video_entry_service.process_fast_video_entry(temp_video_path)
        return success_response(data=draft_records, msg=f"成功从视频中提取 {len(draft_records)} 条记录")

    finally:
        if os.path.exists(temp_video_path):
            os.remove(temp_video_path)

@router.post("/batch-save", response_model=StandardResponse[List[FoodRecord]])
async def batch_save_drafts(
    records: List[FoodRecordCreate],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    saved_records = food_record_service.batch_create_records(db=db, records_in=records, user_id=current_user.id)
    return success_response(data=saved_records, msg="所有饮食记录已成功入库")