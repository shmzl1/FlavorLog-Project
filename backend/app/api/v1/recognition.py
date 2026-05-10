# backend/app/api/v1/recognition.py
import os
import cv2
import tempfile
import numpy as np
from typing import List
from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.food_record import FoodRecordCreate
from app.schemas.response import StandardResponse, success_response

# 引入核心服务与算法组件
from app.services.video_entry_service import VideoEntryService
from app.services.food_record_service import FoodRecordService
from app.algorithms.vision.yolo_detector import YoloFoodDetector
from app.algorithms.llm.standardizer import RecordStandardizer

router = APIRouter()

# 依赖注入单例（实际生产中建议使用 FastAPI 的 Depends 进行管理，这里保持你的风格）
video_entry_service = VideoEntryService()
yolo_detector = YoloFoodDetector(model_path="models/yolov8n.pt")
standardizer = RecordStandardizer()
food_record_service = FoodRecordService()

@router.post("/photo", response_model=StandardResponse[FoodRecordCreate])
async def recognize_photo_to_draft(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    【单张图片识别接口】
    作用：接收用户上传的图片，经过 YOLO 检测后，标准化为 FoodRecordCreate 草稿。
    """
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="请上传有效的图片文件")
        
    image_bytes = await file.read()
    nparr = np.frombuffer(image_bytes, np.uint8)
    image_cv2 = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if image_cv2 is None:
        raise HTTPException(status_code=400, detail="图片解码失败，请检查文件损坏情况")
        
    # 这里是原有逻辑，调用 yolo 进行检测并返回
    yolo_result = yolo_detector.detect_image(image_cv2)
    standardized_record = standardizer.ai_result_to_food_record(yolo_result)
    
    return success_response(data=standardized_record, msg="图片识别成功")


@router.post("/video-fast-entry", response_model=StandardResponse[List[FoodRecordCreate]])
async def recognize_video_fast_entry(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    【视频极速录入 API】 (任务 9)
    作用：接收客户端上传的短视频（通常为餐桌全景扫视），触发后台的多模态解析流水线。
    流水线包含：视频关键帧去模糊抽取 -> 语音识别 -> YOLO目标检测 -> 视音频对齐 -> 大模型标准化。
    
    难点与设计：
    由于各种 CV/ASR 库通常需要物理文件路径而不是内存流，这里使用了 tempfile 安全地
    将上传的视频落盘，并在处理结束后利用 finally 块确保清理临时文件，防止服务器磁盘打满。
    """
    # 1. 校验文件类型
    if not file.content_type or not file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="必须上传合法的视频文件 (如 MP4, MOV 等)")

    temp_video_path = ""
    try:
        # 2. 将视频流写入临时文件 (delete=False 保证在 Windows 环境下跨模块读取不报错)
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
            content = await file.read()
            tmp.write(content)
            temp_video_path = tmp.name

        # 3. 核心调用：移交给 VideoEntryService 执行多模态算法调度
        # 这会同步触发任务 10~15
        draft_records = video_entry_service.process_fast_video_entry(temp_video_path)

        if not draft_records:
            return success_response(data=[], msg="视频中未识别到明确的饮食记录")

        return success_response(data=draft_records, msg=f"成功从视频中提取 {len(draft_records)} 条记录")

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"视频极速录入处理失败: {str(e)}")
        
    finally:
        # 4. 资源清理：无论成功失败，必须删除临时视频文件释放磁盘
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                os.remove(temp_video_path)
            except Exception as cleanup_err:
                print(f"清理临时视频文件失败: {cleanup_err}")