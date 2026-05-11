# backend/app/api/v1/recognition.py
import os
import cv2
import uuid
import shutil
import tempfile
import numpy as np
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from celery.result import AsyncResult

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.food_record import FoodRecordCreate
from app.schemas.response import StandardResponse, success_response

from app.services.video_entry_service import VideoEntryService
from app.services.food_record_service import FoodRecordService
from app.algorithms.vision.yolo_detector import YoloFoodDetector
from app.algorithms.llm.standardizer import RecordStandardizer

# 引入刚刚写好的 Celery 异步任务
from app.tasks.video_tasks import process_video_async_task

router = APIRouter()

# 实例化核心服务
video_entry_service = VideoEntryService()
yolo_detector = YoloFoodDetector(model_path="models/yolov8n.pt")
standardizer = RecordStandardizer()
food_record_service = FoodRecordService()


@router.post("/photo", response_model=StandardResponse[FoodRecordCreate])
async def recognize_photo_to_draft(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """【单张图片识别接口】"""
    if file.content_type is None or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="请上传有效的图片文件")
        
    image_bytes = await file.read()
    nparr = np.frombuffer(image_bytes, np.uint8)
    image_cv2 = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if image_cv2 is None:
        raise HTTPException(status_code=400, detail="图片解码失败，请检查文件损坏情况")
        
    yolo_result = yolo_detector.detect_image(image_cv2)
    standardized_record = standardizer.ai_result_to_food_record(yolo_result)
    
    return success_response(data=standardized_record, msg="图片识别成功")


@router.post("/video-fast-entry", response_model=StandardResponse[List[FoodRecordCreate]])
async def recognize_video_fast_entry(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    【视频极速录入 API (同步阻塞版)】
    保留的同步接口。如果前端想直接一直转圈等结果，可以调用这个接口。
    """
    if file.content_type is None or not file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="必须上传合法的视频文件 (如 MP4, MOV 等)")

    temp_video_path = ""
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
            # 【内存优化】使用 shutil 流式落盘，替代 await file.read()，防止大视频撑爆内存
            shutil.copyfileobj(file.file, tmp)
            temp_video_path = tmp.name

        draft_records = video_entry_service.process_fast_video_entry(temp_video_path)

        if not draft_records:
            return success_response(data=[], msg="视频中未识别到明确的饮食记录")

        return success_response(data=draft_records, msg=f"成功从视频中提取 {len(draft_records)} 条记录")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"视频极速录入处理失败: {str(e)}")
        
    finally:
        video_entry_service.release_resources()
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                os.remove(temp_video_path)
            except Exception:
                pass


@router.post("/video-fast-entry/async")
async def upload_video_for_async_entry(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    【升级版：异步极速录入投递接口 (Celery 架构)】
    用户上传视频后，0.1秒内立刻返回 task_id，绝不卡顿主线程。
    任务交给后端的 Celery Worker 处理。
    """
    if file.content_type is None or not file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="必须上传合法的视频文件")

    # 1. 安全暂存视频到本地
    os.makedirs("uploads", exist_ok=True)
    temp_filename = f"uploads/temp_{uuid.uuid4().hex}_{file.filename}"
    
    # 【内存优化】使用 shutil 进行流式落盘
    # 无论视频是 10MB 还是 1GB，内存占用始终只有几 KB
    with open(temp_filename, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # 2. 将任务丢入 Redis 队列让 Celery Worker 去跑
    # .delay() 会立即响应，无需等待视频处理完毕
    task = process_video_async_task.delay(video_path=temp_filename, user_id=current_user.id)

    # 3. 将取餐码 (task_id) 交给前端
    return success_response(data={"task_id": task.id}, msg="视频已加入 AI 处理队列")


@router.get("/video-fast-entry/status/{task_id}")
def check_video_processing_status(task_id: str, current_user: User = Depends(get_current_user)):
    """
    【录入进度轮询接口 (Celery 架构)】
    前端每隔 2 秒调用一次这个接口，拿着 task_id 去 Redis 查询 Celery 进度。
    """
    task_result = AsyncResult(task_id)
    
    if task_result.state == 'PENDING':
        response = {"status": "PENDING", "message": "排队中，前面可能还有别的视频..."}
    elif task_result.state == 'PROCESSING':
        # 这里会实时获取到你在 video_tasks.py 里用 self.update_state 写进去的 progress 信息
        response = {"status": "PROCESSING", "message": task_result.info.get('progress', 'AI 处理中...')}
    elif task_result.state == 'SUCCESS':
        # 处理完成，把提取好的食物列表吐给前端
        response = {"status": "SUCCESS", "data": task_result.result.get("data")}
    elif task_result.state == 'FAILURE':
        response = {"status": "FAILURE", "message": "处理失败，可能是视频无法解析"}
    else:
        response = {"status": task_result.state}

    return success_response(data=response)