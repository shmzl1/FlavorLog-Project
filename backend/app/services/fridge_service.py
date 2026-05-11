# backend/app/services/fridge_service.py

from typing import List, Optional

from sqlalchemy.orm import Session

from app.models.fridge_item import FridgeItem
from app.schemas.fridge import FridgeItemCreate, FridgeItemUpdate

class FridgeService:
    def get_user_items(self, db: Session, *, user_id: int, skip: int = 0, limit: int = 100) -> List[FridgeItem]:
        return FridgeService.get_items_by_user(db, user_id=user_id, skip=skip, limit=limit)

    def create_item(self, db: Session, obj_in: FridgeItemCreate, *, user_id: int) -> FridgeItem:
        return FridgeService.create_item(db, obj_in, user_id=user_id)

    def update_item(
        self, db: Session, item_id: int, *, user_id: int, obj_in: FridgeItemUpdate
    ) -> Optional[FridgeItem]:
        db_item = FridgeService.get_item_by_id(db, item_id, user_id=user_id)
        if not db_item:
            return None
        return FridgeService.update_item(db, db_item=db_item, item_in=obj_in)

    def delete_item(self, db: Session, *, item_id: int, user_id: int) -> Optional[FridgeItem]:
        db_item = FridgeService.get_item_by_id(db, item_id, user_id=user_id)
        if not db_item:
            return None
        return FridgeService.delete_item(db, db_item=db_item)

    @staticmethod
    def create_item(db: Session, obj_in: FridgeItemCreate, *, user_id: int) -> FridgeItem:
        db_item = FridgeItem(
            **obj_in.model_dump(),
            user_id=user_id,
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    @staticmethod
    def get_items_by_user(db: Session, *, user_id: int, skip: int = 0, limit: int = 100) -> List[FridgeItem]:
        return (
            db.query(FridgeItem)
            .filter(FridgeItem.user_id == user_id)
            .offset(skip)
            .limit(limit)
            .all()
        )

    @staticmethod
    def get_item_by_id(db: Session, item_id: int, *, user_id: int) -> Optional[FridgeItem]:
        return (
            db.query(FridgeItem)
            .filter(FridgeItem.id == item_id, FridgeItem.user_id == user_id)
            .first()
        )

    @staticmethod
    def update_item(db: Session, *, db_item: FridgeItem, item_in: FridgeItemUpdate) -> FridgeItem:
        update_data = item_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_item, field, value)
        
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    @staticmethod
    def delete_item(db: Session, *, db_item: FridgeItem) -> FridgeItem:
        db.delete(db_item)
        db.commit()
        return db_item


fridge_service = FridgeService()
