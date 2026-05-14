# backend/app/services/fridge_service.py

from typing import List, Optional
from sqlalchemy.orm import Session

from app.models.fridge_item import FridgeItem
from app.schemas.fridge import FridgeItemCreate, FridgeItemUpdate

# [FridgeService] 是冰箱食材的核心业务逻辑类。
# 封装了所有对数据库 FridgeItem 表的直接操作，确保 API 层不直接接触复杂的 SQL 查询。
class FridgeService:
    
    @staticmethod
    def get_items_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[FridgeItem]:
        """
        根据用户 ID 获取其冰箱内所有的食材列表。
        支持 skip 和 limit 扩展分页功能。
        """
        return db.query(FridgeItem).filter(
            FridgeItem.user_id == user_id
        ).offset(skip).limit(limit).all()

    @staticmethod
    def get_item_by_id(db: Session, item_id: int, user_id: int) -> Optional[FridgeItem]:
        """
        根据食材 ID 获取单条记录。
        增加了 user_id 校验，确保用户只能查询到属于自己的食材，防止越权漏洞。
        """
        return db.query(FridgeItem).filter(
            FridgeItem.id == item_id, 
            FridgeItem.user_id == user_id
        ).first()

    @staticmethod
    def create_item(db: Session, obj_in: FridgeItemCreate, user_id: int) -> FridgeItem:
        """
        在数据库中创建一条新的食材记录。
        使用 model_dump() 自动解包 Pydantic 模型。
        """
        db_item = FridgeItem(
            **obj_in.model_dump(),
            user_id=user_id,
        )
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    @staticmethod
    def update_item(db: Session, item_id: int, user_id: int, obj_in: FridgeItemUpdate) -> Optional[FridgeItem]:
        """
        更新食材信息。
        内部先调用 get_item_by_id 进行权限校验，只有归属于当前用户的食材才允许修改。
        """
        # 1. 先定位该食材是否存在且属于该用户
        db_item = FridgeService.get_item_by_id(db, item_id=item_id, user_id=user_id)
        if not db_item:
            return None
            
        # 2. 提取需要更新的字段（过滤掉前端未传的字段）
        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_item, field, value)
        
        db.add(db_item)
        db.commit()
        db.refresh(db_item)
        return db_item

    @staticmethod
    def delete_item(db: Session, item_id: int, user_id: int) -> Optional[FridgeItem]:
        """
        从数据库中物理删除指定的食材记录。
        """
        db_item = FridgeService.get_item_by_id(db, item_id=item_id, user_id=user_id)
        if db_item:
            db.delete(db_item)
            db.commit()
        return db_item

# 实例化一个全局单例，方便部分习惯使用实例调用的路由
fridge_service = FridgeService()