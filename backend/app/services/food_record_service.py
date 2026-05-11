# backend/app/services/food_record_service.py

from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.food_record import FoodRecord, FoodRecordItem
from app.models.fridge_item import FridgeItem
from app.schemas.food_record import FoodRecordCreate, FoodRecordUpdate

class FoodRecordService:

    @staticmethod
    def create_record(db: Session, record_in: FoodRecordCreate, user_id: int) -> FoodRecord:
        """新增单条饮食记录"""
        record_data = record_in.model_dump()
        items_data = record_data.pop("items", [])
        
        db_record = FoodRecord(**record_data, user_id=user_id)
        
        for item_data in items_data:
            db_item = FoodRecordItem(**item_data)
            db_record.items.append(db_item)
            
        db.add(db_record)
        db.commit()
        db.refresh(db_record)
        
        return db_record

    @staticmethod
    def batch_create_records(db: Session, records_in: List[FoodRecordCreate], user_id: int) -> List[FoodRecord]:
        """批量创建饮食记录，并联动扣减赛博冰箱库存"""
        db_records = []
        consumed_foods = {}
        
        for record_in in records_in:
            record_data = record_in.model_dump()
            items_data = record_data.pop("items", [])
            
            db_record = FoodRecord(**record_data, user_id=user_id)
            
            for item_data in items_data:
                db_item = FoodRecordItem(**item_data)
                db_record.items.append(db_item)
                
                food_name = item_data.get("food_name")
                weight = item_data.get("weight_g")
                
                if food_name:
                    safe_weight = float(weight) if weight is not None else 100.0
                    consumed_foods[food_name] = consumed_foods.get(food_name, 0.0) + safe_weight
            
            db_records.append(db_record)
            
        db.add_all(db_records)
        
        # ==========================================
        # 💡 核心修复：使用 getattr 和 setattr 完美绕过 Pylance 类型检查警告
        # ==========================================
        for food_name, consumed_weight in consumed_foods.items():
            fridge_items = db.query(FridgeItem).filter(
                FridgeItem.user_id == user_id,
                FridgeItem.name.ilike(f"%{food_name}%"),
                FridgeItem.quantity > 0  
            ).order_by(FridgeItem.expiration_date.asc()).all()  
            
            remaining_to_deduct = consumed_weight
            
            for f_item in fridge_items:
                if remaining_to_deduct <= 0:
                    break
                    
                # 💡 取值：安全地取为 float 类型，红线立刻消失
                current_qty = float(getattr(f_item, 'quantity', 0.0))
                
                if current_qty >= remaining_to_deduct:  
                    # 💡 赋值：使用 setattr 绕过 Pylance 的不可赋值警告
                    setattr(f_item, 'quantity', current_qty - remaining_to_deduct)
                    remaining_to_deduct = 0.0
                else:
                    remaining_to_deduct -= current_qty
                    setattr(f_item, 'quantity', 0.0)
                    
                db.add(f_item)
        
        db.commit()
        
        for record in db_records:
            db.refresh(record)
            
        return db_records

    @staticmethod
    def get_records_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[FoodRecord]:
        """查询饮食记录"""
        return db.query(FoodRecord).filter(FoodRecord.user_id == user_id).order_by(FoodRecord.record_time.desc()).offset(skip).limit(limit).all()

    @staticmethod
    def get_record_by_id(db: Session, record_id: int, user_id: int) -> Optional[FoodRecord]:
        """单条查询辅助"""
        return db.query(FoodRecord).filter(FoodRecord.id == record_id, FoodRecord.user_id == user_id).first()

    @staticmethod
    def update_record(db: Session, db_record: FoodRecord, record_in: FoodRecordUpdate) -> FoodRecord:
        """修改饮食记录"""
        update_data = record_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            # 这里原本用的就是 setattr，所以不报错，这也印证了我们的修复方案！
            setattr(db_record, field, value)
        
        db.add(db_record)
        db.commit()
        db.refresh(db_record)
        return db_record

    @staticmethod
    def delete_record(db: Session, db_record: FoodRecord) -> FoodRecord:
        """删除饮食记录"""
        db.delete(db_record)
        db.commit()
        return db_record