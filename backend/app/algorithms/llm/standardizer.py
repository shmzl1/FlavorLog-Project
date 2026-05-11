# backend/app/algorithms/llm/standardizer.py
from typing import Dict, Any
from app.schemas.food_record import FoodRecordCreate, FoodRecordItemCreate

class RecordStandardizer:
    """
    【AI 识别结果标准化引擎】
    作用：
    担当“数据防线”的角色。负责将底层 YOLO 算法、语音抽取模块传来的非结构化或半结构化字典（Dict），
    进行默认值兜底、数据类型强转、异常值过滤，最终输出严谨的 Pydantic Schema（FoodRecordCreate）。
    防止算法层的脏数据污染业务数据库。
    """
    def __init__(self):
        # 默认一餐的基础热量（如果算法完全没识别出来时的兜底策略）
        self.default_weight_g = 100.0

    def ai_result_to_food_record(self, raw_data: Dict[str, Any]) -> FoodRecordCreate:
        """
        【数据清洗与 Schema 映射】
        参数:
            raw_data: 包含检测框、类别、初步卡路里的原始字典
        返回:
            严格符合后端接口规范的 FoodRecordCreate 对象
        """
        items = []
        raw_foods = raw_data.get("foods", [])
        
        # 1. 提取所有识别到的食物单项
        for food in raw_foods:
            # 安全获取基础属性
            name = food.get("name", "未知食物")
            confidence = float(food.get("confidence", 0.0))
            
            # 如果置信度过低，直接舍弃，防止误识别录入（如置信度 < 0.3）
            if confidence < 0.3:
                continue

            # 安全转换数值型数据，带有兜底机制
            weight = food.get("weight_g")
            weight_g = float(weight) if weight is not None else self.default_weight_g
            
            # 组装子项 Schema
            item = FoodRecordItemCreate(
                food_name=name,
                weight_g=weight_g,
                calories=float(food.get("calories", 0.0)),
                protein_g=float(food.get("protein_g", 0.0)),
                fat_g=float(food.get("fat_g", 0.0)),
                carbohydrate_g=float(food.get("carbohydrate_g", 0.0)),
                confidence=confidence,
                meta_json={"raw_bbox": food.get("box", [])} # 保留原始框坐标以便前端高亮显示
            )
            items.append(item)
            
        # 2. 聚合总计数值 (计算这一顿饭的总摄入)
        total_cal = sum(item.calories for item in items if item.calories)
        total_pro = sum(item.protein_g for item in items if item.protein_g)
        total_fat = sum(item.fat_g for item in items if item.fat_g)
        total_carb = sum(item.carbohydrate_g for item in items if item.carbohydrate_g)

        # 3. 组装主表 Schema
        record_create = FoodRecordCreate(
            meal_type="snack",          # 默认加餐，后续可根据上传时间(早中晚)推断
            source_type="video_ai",     # 标记为视频AI生成
            description="AI自动生成的饮食记录",
            total_calories=total_cal,
            total_protein_g=total_pro,
            total_fat_g=total_fat,
            total_carbohydrate_g=total_carb,
            raw_result_json=raw_data,
            items=items
        )

        return record_create