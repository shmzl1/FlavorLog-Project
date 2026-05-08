# backend/app/services/fridge_service.py

from typing import List, Optional
from sqlalchemy.orm import Session
# 💡 请确保你的模型路径正确，根据你之前的代码这里是 fridge_item
from app.models.fridge_item import FridgeItem 
from app.schemas.fridge import FridgeItemCreate, FridgeItemUpdate

class FridgeService:
    """赛博冰箱 CRUD 业务逻辑"""

    def create_item(self, db: Session, obj_in: FridgeItemCreate, user_id: int) -> FridgeItem:
        """创建食材 (Create)"""
        db_item = FridgeItem(
            **obj_in.model_dump(),  # Pydantic V2 语法
            user_id=user_id         # 绑定当前用户 ID
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    def get_user_items(self, db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[FridgeItem]:
        """查询某用户的所有食材 (Read) - 匹配 API 层调用"""
        return db.query(FridgeItem).filter(
            FridgeItem.user_id == user_id
        ).offset(skip).limit(limit).all()

    def get_item_by_id(self, db: Session, item_id: int, user_id: int) -> Optional[FridgeItem]:
        """根据 ID 查单个食材 (附带用户鉴权)"""
        return db.query(FridgeItem).filter(
            FridgeItem.id == item_id, 
            FridgeItem.user_id == user_id
        ).first()

    def update_item(self, db: Session, item_id: int, user_id: int, obj_in: FridgeItemUpdate) -> Optional[FridgeItem]:
        """更新食材 (Update)"""
        db_item = self.get_item_by_id(db, item_id=item_id, user_id=user_id)
        if not db_item:
            return None
            
        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_item, field, value)
        
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    def delete_item(self, db: Session, item_id: int, user_id: int) -> Optional[FridgeItem]:
        """删除食材 (Delete) - 匹配 API 层直接传 ID 的调用方式"""
        db_item = self.get_item_by_id(db, item_id=item_id, user_id=user_id)
        if db_item:
            db.delete(db_item)
            db.commit()
        return db_item

# 💡 核心修复：创建一个实例并导出。
# 这样在 v1/fridge.py 中使用 from app.services.fridge_service import fridge_service 时才不会报“未知符号”
fridge_service = FridgeService()