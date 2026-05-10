from typing import Annotated, List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.fridge import FridgeItemCreate, FridgeItemResponse, FridgeItemUpdate
from app.services.fridge_service import FridgeService
from app.utils.response import success_response


router = APIRouter()


@router.post("/", status_code=status.HTTP_201_CREATED)
def add_item(
    item_in: FridgeItemCreate,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    item = FridgeService.create_item(db, item_in, user_id=current_user.id)
    return success_response(data=FridgeItemResponse.model_validate(item).model_dump())


@router.get("/")
def list_items(
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    skip: int = 0,
    limit: int = 100,
):
    items = FridgeService.get_items_by_user(db, user_id=current_user.id, skip=skip, limit=limit)
    data = [FridgeItemResponse.model_validate(x).model_dump() for x in items]
    return success_response(data=data)


@router.put("/{item_id}", responses={404: {"description": "Not Found"}})
def update_item(
    item_id: int,
    item_in: FridgeItemUpdate,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    db_item = FridgeService.get_item_by_id(db, item_id, user_id=current_user.id)
    if not db_item:
        raise HTTPException(status_code=404, detail="未找到该食材，或无权操作")
    updated = FridgeService.update_item(db, db_item=db_item, item_in=item_in)
    return success_response(data=FridgeItemResponse.model_validate(updated).model_dump())


@router.delete("/{item_id}", responses={404: {"description": "Not Found"}})
def delete_item(
    item_id: int,
    db: Annotated[Session, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    db_item = FridgeService.get_item_by_id(db, item_id, user_id=current_user.id)
    if not db_item:
        raise HTTPException(status_code=404, detail="未找到该食材，或无权操作")
    deleted = FridgeService.delete_item(db, db_item=db_item)
    return success_response(data=FridgeItemResponse.model_validate(deleted).model_dump())
