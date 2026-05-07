# backend/app/services/fridge_service.py

from sqlalchemy.orm import Session
from app.models.fridge_item import FridgeItem
from app.schemas.fridge import FridgeItemCreate, FridgeItemUpdate

class FridgeService:
    """赛博冰箱 CRUD 业务逻辑"""

    @staticmethod
    def create_item(db: Session, item_in: FridgeItemCreate, user_id: int) -> FridgeItem:
        """创建食材 (Create)"""
        db_item = FridgeItem(
            **item_in.model_dump(),  # Pydantic V2 语法，将 schema 转为字典并解包
            user_id=user_id          # 强行绑定当前操作的用户 ID
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    @staticmethod
    def get_items_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100):
        """查询某用户的所有食材 (Read)"""
        return db.query(FridgeItem).filter(FridgeItem.user_id == user_id).offset(skip).limit(limit).all()

    @staticmethod
    def get_item_by_id(db: Session, item_id: int, user_id: int) -> FridgeItem | None:
        """根据 ID 查单个食材 (附带用户鉴权)"""
        return db.query(FridgeItem).filter(
            FridgeItem.id == item_id, 
            FridgeItem.user_id == user_id
        ).first()

    @staticmethod
    def update_item(db: Session, db_item: FridgeItem, item_in: FridgeItemUpdate) -> FridgeItem:
        """更新食材 (Update)"""
        update_data = item_in.model_dump(exclude_unset=True) # 只提取前端真正传了值的字段
        for field, value in update_data.items():
            setattr(db_item, field, value)
        
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    @staticmethod
    def delete_item(db: Session, db_item: FridgeItem) -> FridgeItem:
        """删除食材 (Delete)"""
        db.delete(db_item)
        db.commit()
        return db_item