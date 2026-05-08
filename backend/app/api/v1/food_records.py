# backend/app/api/v1/food_records.py

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

# 导入公共依赖
from app.api.deps import get_db, get_current_user
from app.models.user import User

# 💡 核心规范：导入统一响应工具
from app.schemas.response import StandardResponse, success_response

# 导入数据契约
from app.schemas.food_record import (
    FoodRecordCreate, 
    FoodRecordUpdate, 
    FoodRecordResponse,
    PhotoRecognitionRequest  # 记得在 schema 文件里定义这个类
)
from app.services.food_record_service import FoodRecordService

router = APIRouter()

# ==========================================
# 1. 【C】记录吃了一顿饭
# ==========================================
@router.post("/", response_model=StandardResponse[FoodRecordResponse], status_code=status.HTTP_201_CREATED)
def add_food_record(
    record_in: FoodRecordCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【C】记录吃了一顿饭"""
    record = FoodRecordService.create_record(db, record_in, user_id=current_user.id)
    return success_response(data=record, msg="饮食记录已保存")

# ==========================================
# 2. 【R】查看我的饮食历史日记
# ==========================================
@router.get("/", response_model=StandardResponse[List[FoodRecordResponse]])
def read_food_records(
    skip: int = 0, limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【R】查看我的饮食历史日记"""
    records = FoodRecordService.get_records_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    return success_response(data=records)

# ==========================================
# 3. 【U】修改某顿饭的信息
# ==========================================
@router.put("/{record_id}", response_model=StandardResponse[FoodRecordResponse])
def update_food_record(
    record_id: int,
    record_in: FoodRecordUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【U】修改某顿饭的信息（比如卡路里估算错了）"""
    db_record = FoodRecordService.get_record_by_id(db, record_id, user_id=current_user.id)
    if not db_record:
        raise HTTPException(status_code=404, detail="未找到该记录，或无权操作")
    
    updated_record = FoodRecordService.update_record(db, db_record=db_record, record_in=record_in)
    return success_response(data=updated_record, msg="记录已更新")

# ==========================================
# 4. 【D】删除某条饮食记录
# ==========================================
@router.delete("/{record_id}", response_model=StandardResponse[FoodRecordResponse])
def delete_food_record(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【D】删除某条饮食记录"""
    db_record = FoodRecordService.get_record_by_id(db, record_id, user_id=current_user.id)
    if not db_record:
        raise HTTPException(status_code=404, detail="未找到该记录，或无权操作")
    
    deleted_record = FoodRecordService.delete_record(db, db_record=db_record)
    return success_response(data=deleted_record, msg="记录已成功删除")

# ==========================================
# 5. 【AI Mock】图片识别接口 (你的 KPI 关键项)
# ==========================================
@router.post("/photo-recognition", response_model=StandardResponse)
def mock_photo_recognition(
    req: PhotoRecognitionRequest,
    current_user: User = Depends(get_current_user)
):
    """
    【AI 识别】图片识别生成饮食记录草稿 (阶段一 Mock)
    """
    # 严格按照《接口文档.md》8.6 章节的结构返回数据
    mock_data = {
        "draft_id": "draft_001",
        "source_type": "photo",
        "items": [
            {
                "food_name": "番茄炒蛋",
                "weight_g": 200,
                "calories": 210,
                "protein_g": 12,
                "fat_g": 14,
                "carbohydrate_g": 8,
                "confidence": 0.82
            }
        ],
        "need_user_confirm": True
    }
    
    return success_response(data=mock_data, msg="图片识别成功(Mock)")