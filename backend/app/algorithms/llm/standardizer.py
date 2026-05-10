from datetime import datetime
from app.schemas.food_record import FoodRecordCreate, FoodRecordItemCreate
from typing import Dict, Any

class RecordStandardizer:
    """
    数据结构标准化类。
    
    【作用】
    各大 AI 模型（例如 GPT-4V、YOLO 食材识别等）输出的数据格式往往是非标准化的 JSON。
    此类负责将原始 AI 识别结果映射、清洗并转换为后端严格定义的 FoodRecordCreate 格式。
    这保证了进入 Controller 和 Service 层的数据是100%合法和类型安全的。
    """

    @staticmethod
    def ai_result_to_food_record(raw_ai_data: Dict[str, Any]) -> FoodRecordCreate:
        """
        【作用】将多模态大模型的识别字典，转换为 FastAPI 兼容的 Pydantic 模型。
        """
        # 1. 提取或设置基础信息
        meal_type = raw_ai_data.get("meal_type", "snack")
        description = raw_ai_data.get("summary", "AI自动识别生成的饮食记录")
        record_time = datetime.now() # 或者从 raw_ai_data 获取拍摄时间

        # 2. 遍历并标准化所有的食材项目
        standardized_items = []
        raw_items = raw_ai_data.get("foods", [])
        
        for item in raw_items:
            # 数据清洗与兜底处理
            weight = float(item.get("weight_g", 0))
            calories = float(item.get("calories", 0))
            
            standardized_item = FoodRecordItemCreate(
                food_name=item.get("name", "未知食物"),
                weight_g=weight if weight > 0 else None,
                calories=calories,
                protein_g=float(item.get("protein", 0)),
                fat_g=float(item.get("fat", 0)),
                carbohydrate_g=float(item.get("carbs", 0)),
                confidence=float(item.get("ai_confidence", 0.8)),
                meta_json={"bbox": item.get("bbox", [])}
            )
            standardized_items.append(standardized_item)

        # 3. 组装父级记录
        food_record = FoodRecordCreate(
            meal_type=meal_type,
            record_time=record_time,
            source_type="ai_vision",  # 明确标记来源为 AI 视觉
            description=description,
            total_calories=sum(i.calories for i in standardized_items if i.calories),
            total_protein_g=sum(i.protein_g for i in standardized_items if i.protein_g),
            total_fat_g=sum(i.fat_g for i in standardized_items if i.fat_g),
            total_carbohydrate_g=sum(i.carbohydrate_g for i in standardized_items if i.carbohydrate_g),
            raw_result_json=raw_ai_data, # 保留原始 JSON 以便日后回溯分析
            items=standardized_items
        )

        return food_record