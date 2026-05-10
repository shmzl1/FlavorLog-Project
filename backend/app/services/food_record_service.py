# backend/app/services/food_record_service.py

from sqlalchemy.orm import Session
from typing import List
from app.models.food_record import FoodRecord, FoodRecordItem
from app.schemas.food_record import FoodRecordCreate, FoodRecordUpdate

class FoodRecordService:

    @staticmethod
    def create_record(db: Session, record_in: FoodRecordCreate, user_id: int) -> FoodRecord:
        """【增】创建单条饮食记录 (包含多条明细的嵌套写入)"""
        
        # 1. 把 Pydantic 对象转为字典
        record_data = record_in.model_dump()
        
        # 2. 把子表的数据 (items) 从主表数据中抽离出来
        items_data = record_data.pop("items", [])
        
        # 3. 创建主表 ORM 对象
        db_record = FoodRecord(**record_data, user_id=user_id)
        
        # 4. 循环创建子表 ORM 对象，并直接挂载到主表的 .items 关系列表上
        # SQLAlchemy 会自动处理它们之间的 ID 外键关联！
        for item_data in items_data:
            db_item = FoodRecordItem(**item_data)
            db_record.items.append(db_item)
            
        # 5. 提交事务 (主表和所有子表将作为一个整体写入数据库)
        db.add(db_record)
        db.commit()
        db.refresh(db_record)
        
        return db_record

    @staticmethod
    def batch_create_records(db: Session, records_in: List[FoodRecordCreate], user_id: int) -> List[FoodRecord]:
        """
        【增-批量】批量创建多条饮食记录 (专为视频极速录入、AI多帧识别场景设计)
        优势：只开启一次事务，将视频分析出的所有片段记录一次性打入数据库，性能极高。
        """
        db_records = []
        
        for record_in in records_in:
            record_data = record_in.model_dump()
            items_data = record_data.pop("items", [])
            
            db_record = FoodRecord(**record_data, user_id=user_id)
            
            for item_data in items_data:
                db_item = FoodRecordItem(**item_data)
                db_record.items.append(db_item)
            
            db_records.append(db_record)
            
        # 批量添加到会话
        db.add_all(db_records)
        # 一次性提交全部事务
        db.commit()
        
        # 刷新所有记录以获取数据库自动生成的自增 ID
        for record in db_records:
            db.refresh(record)
            
        return db_records

    @staticmethod
    def get_records_by_user(db: Session, user_id: int, skip: int = 0, limit: int = 100) -> List[FoodRecord]:
        """【查】获取列表"""
        return db.query(FoodRecord)\
                 .filter(FoodRecord.user_id == user_id)\
                 .order_by(FoodRecord.record_time.desc())\
                 .offset(skip).limit(limit).all()

    @staticmethod
    def get_record_by_id(db: Session, record_id: int, user_id: int) -> FoodRecord | None:
        """【查】单条记录"""
        return db.query(FoodRecord)\
                 .filter(FoodRecord.id == record_id, FoodRecord.user_id == user_id)\
                 .first()

    @staticmethod
    def update_record(db: Session, db_record: FoodRecord, record_in: FoodRecordUpdate) -> FoodRecord:
        """
        【改】修改记录的主表信息。
        注意：通常我们只修改主表的备注、餐别等。
        如果需要修改子表（具体的食物明细），业务上一般是通过增加专门的增删子表接口来实现。
        """
        update_data = record_in.model_dump(exclude_unset=True) # 只提取前端传了值的字段
        for field, value in update_data.items():
            setattr(db_record, field, value)
        
        db.add(db_record)
        db.commit()
        db.refresh(db_record)
        return db_record

    @staticmethod
    def delete_record(db: Session, db_record: FoodRecord) -> FoodRecord:
        """
        【删】删除记录。
        得益于我们在 models 里配置了 cascade="all, delete-orphan"，
        只要删除了这顿饭，里面所有的食物明细都会被数据库自动清理得干干净净！
        """
        db.delete(db_record)
        db.commit()
        return db_record