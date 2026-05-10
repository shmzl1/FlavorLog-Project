from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.food_record import FoodRecordCreate, FoodRecordResponse, FoodRecordUpdate
from app.services.food_record_service import FoodRecordService
from app.utils.response import success_response


router = APIRouter()


@router.post("/", status_code=status.HTTP_201_CREATED)
def add_record(
    record_in: FoodRecordCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    record = FoodRecordService.create_record(db, record_in, user_id=current_user.id)
    return success_response(data=FoodRecordResponse.model_validate(record).model_dump())


@router.get("/")
def list_records(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    records = FoodRecordService.get_records_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    data = [FoodRecordResponse.model_validate(x).model_dump() for x in records]
    return success_response(data=data)


@router.put("/{record_id}")
def update_record(
    record_id: int,
    record_in: FoodRecordUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db_record = FoodRecordService.get_record_by_id(db, record_id=record_id, user_id=current_user.id)
    if not db_record:
        raise HTTPException(status_code=404, detail="未找到该记录，或无权操作")
    updated = FoodRecordService.update_record(db, db_record=db_record, record_in=record_in)
    return success_response(data=FoodRecordResponse.model_validate(updated).model_dump())


@router.delete("/{record_id}")
def delete_record(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db_record = FoodRecordService.get_record_by_id(db, record_id=record_id, user_id=current_user.id)
    if not db_record:
        raise HTTPException(status_code=404, detail="未找到该记录，或无权操作")
    deleted = FoodRecordService.delete_record(db, db_record=db_record)
    return success_response(data=FoodRecordResponse.model_validate(deleted).model_dump())
