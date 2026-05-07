# backend/app/api/v1/food_records.py

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.food_record import FoodRecordCreate, FoodRecordUpdate, FoodRecordResponse
from app.services.food_record_service import FoodRecordService

router = APIRouter()

@router.post("/", response_model=FoodRecordResponse, status_code=status.HTTP_201_CREATED)
def add_food_record(
    record_in: FoodRecordCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【C】记录吃了一顿饭"""
    return FoodRecordService.create_record(db, record_in, user_id=current_user.id)

@router.get("/", response_model=List[FoodRecordResponse])
def read_food_records(
    skip: int = 0, limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【R】查看我的饮食历史日记"""
    return FoodRecordService.get_records_by_user(db, user_id=current_user.id, skip=skip, limit=limit)

@router.put("/{record_id}", response_model=FoodRecordResponse)
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
    return FoodRecordService.update_record(db, db_record=db_record, record_in=record_in)

@router.delete("/{record_id}", response_model=FoodRecordResponse)
def delete_food_record(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【D】删除某条饮食记录"""
    db_record = FoodRecordService.get_record_by_id(db, record_id, user_id=current_user.id)
    if not db_record:
        raise HTTPException(status_code=404, detail="未找到该记录，或无权操作")
    return FoodRecordService.delete_record(db, db_record=db_record)