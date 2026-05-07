# backend/app/api/v1/fridge.py

from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.fridge import FridgeItemCreate, FridgeItemUpdate, FridgeItemResponse
from app.services.fridge_service import FridgeService

router = APIRouter()

@router.post("/", response_model=FridgeItemResponse, status_code=status.HTTP_201_CREATED)
def add_fridge_item(
    item_in: FridgeItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【C】往冰箱里放食材"""
    return FridgeService.create_item(db, item_in, user_id=current_user.id)

@router.get("/", response_model=List[FridgeItemResponse])
def read_fridge_items(
    skip: int = 0, limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【R】查看自己冰箱里的所有食材"""
    return FridgeService.get_items_by_user(db, user_id=current_user.id, skip=skip, limit=limit)

@router.put("/{item_id}", response_model=FridgeItemResponse)
def update_fridge_item(
    item_id: int,
    item_in: FridgeItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【U】修改食材信息（比如吃掉了一半）"""
    db_item = FridgeService.get_item_by_id(db, item_id, user_id=current_user.id)
    if not db_item:
        raise HTTPException(status_code=404, detail="未找到该食材，或无权操作")
    return FridgeService.update_item(db, db_item=db_item, item_in=item_in)

@router.delete("/{item_id}", response_model=FridgeItemResponse)
def delete_fridge_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """【D】把坏掉或吃完的食材扔掉"""
    db_item = FridgeService.get_item_by_id(db, item_id, user_id=current_user.id)
    if not db_item:
        raise HTTPException(status_code=404, detail="未找到该食材，或无权操作")
    return FridgeService.delete_item(db, db_item=db_item)