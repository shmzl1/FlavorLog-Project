import os
import cv2
import numpy as np
from pathlib import Path
from typing import Dict, Any, List
# 引入 Ultralytics 的 YOLO
from ultralytics import YOLO

class YoloFoodDetector:
    """
    本地 YOLO 食材/食物检测器。
    
    【作用】
    加载本地 yolov8n.pt 模型，对输入的图像（关键帧）进行目标检测。
    自动过滤非食物类别，并为识别到的食物匹配默认的卡路里和营养素，
    最终输出能够被 RecordStandardizer 解析的标准化 JSON 格式。
    """

    def __init__(self, model_path: str = "models/yolov8n.pt", conf_threshold: float = 0.45):
        """
        :param model_path: 本地 YOLO 权重文件的路径 (建议将 yolov8n.pt 放在项目根目录的 models 文件夹下)
        :param conf_threshold: 置信度阈值，低于该值的识别结果将被丢弃
        """
        # 💡 核心修复：动态获取项目根目录，确保路径在任何启动环境下都有效
        # __file__ 是当前文件的路径，通过 .parent 追溯到 backend 根目录
        base_path = Path(__file__).resolve().parent.parent.parent.parent
        full_model_path = base_path / model_path

        # 检查模型文件是否存在
        if not full_model_path.exists():
            # 兜底：如果 models/ 目录下没有，尝试在根目录直接寻找
            alt_path = base_path / "yolov8n.pt"
            if alt_path.exists():
                full_model_path = alt_path
            else:
                raise FileNotFoundError(
                    f"找不到 YOLO 模型文件: {full_model_path}\n"
                    f"请确保项目根目录下存在 models 文件夹，并将 yolov8n.pt 放入其中。"
                )
            
        # 加载模型 (注意：ultralytics 接收字符串路径)
        self.model = YOLO(str(full_model_path))
        self.conf_threshold = conf_threshold
        
        # COCO 数据集 (yolov8n 默认数据集) 中的食物相关类别 ID
        # 46: banana, 47: apple, 48: sandwich, 49: orange, 50: broccoli
        # 51: carrot, 52: hot dog, 53: pizza, 54: donut, 55: cake
        self.valid_food_class_ids = {46, 47, 48, 49, 50, 51, 52, 53, 54, 55}

        # Mock 本地食物营养库（每 100g 的营养成分）
        # 实际生产中，这里应该调用数据库服务 (Service层) 来查询
        self.mock_nutrition_db = {
            "banana": {"name": "香蕉", "calories": 89, "protein": 1.1, "fat": 0.3, "carbs": 22.8},
            "apple": {"name": "苹果", "calories": 52, "protein": 0.3, "fat": 0.2, "carbs": 13.8},
            "sandwich": {"name": "三明治", "calories": 250, "protein": 12.0, "fat": 10.0, "carbs": 30.0},
            "orange": {"name": "橘子", "calories": 47, "protein": 0.9, "fat": 0.1, "carbs": 11.8},
            "broccoli": {"name": "西兰花", "calories": 34, "protein": 2.8, "fat": 0.4, "carbs": 6.6},
            "carrot": {"name": "胡萝卜", "calories": 41, "protein": 0.9, "fat": 0.2, "carbs": 9.6},
            "hot dog": {"name": "热狗", "calories": 290, "protein": 10.0, "fat": 26.0, "carbs": 4.0},
            "pizza": {"name": "披萨", "calories": 266, "protein": 11.0, "fat": 10.0, "carbs": 33.0},
            "donut": {"name": "甜甜圈", "calories": 452, "protein": 4.9, "fat": 25.0, "carbs": 51.0},
            "cake": {"name": "蛋糕", "calories": 257, "protein": 3.2, "fat": 13.0, "carbs": 32.0},
        }

    def detect_image(self, image: np.ndarray) -> Dict[str, Any]:
        """
        【作用】对单张 OpenCV 图像阵列进行目标检测。
        
        【返回】返回一个可以直接喂给 RecordStandardizer.ai_result_to_food_record 的字典结构。
        """
        # 1. 运行 YOLO 推理
        # verbose=False 可以关闭控制台的大量打印，保持后端日志干净
        results = self.model(image, verbose=False)
        
        detected_foods = []
        
        # 2. 解析推理结果
        for result in results:
            boxes = result.boxes
            for box in boxes:
                # 获取类别 ID、置信度和边界框坐标
                # 💡 使用 .item() 确保将 Tensor 转为原生 Python 类型，防止 JSON 序列化失败
                class_id = int(box.cls[0].item())
                confidence = float(box.conf[0].item())
                xyxy = box.xyxy[0].tolist() # [x_min, y_min, x_max, y_max]

                # 3. 过滤：置信度不足，或者不是食物（比如识别到了人或者桌子），直接跳过
                if confidence < self.conf_threshold or class_id not in self.valid_food_class_ids:
                    continue

                # 4. 提取名称并匹配营养数据
                eng_name = self.model.names[class_id]
                nutrition_info = self.mock_nutrition_db.get(eng_name, {
                    "name": eng_name, "calories": 100, "protein": 0, "fat": 0, "carbs": 0
                })

                # 假设每份被识别到的食物默认是 100g (后续可以通过 3D 深度或大小估算算法优化)
                default_weight = 100.0

                detected_foods.append({
                    "name": nutrition_info["name"],
                    "weight_g": default_weight,
                    "calories": nutrition_info["calories"] * (default_weight / 100),
                    "protein": nutrition_info["protein"] * (default_weight / 100),
                    "fat": nutrition_info["fat"] * (default_weight / 100),
                    "carbs": nutrition_info["carbs"] * (default_weight / 100),
                    "ai_confidence": round(confidence, 4),
                    "bbox": xyxy
                })

        # 5. 组装为标准多模态输出格式
        food_names_str = "、".join(list(set([f["name"] for f in detected_foods]))) if detected_foods else "未知食物"
        
        return {
            "meal_type": "snack", # 默认可以设为加餐，或者在 Service 层根据当前时间覆盖
            "summary": f"YOLO 本地视觉模型自动识别到了：{food_names_str}",
            "foods": detected_foods
        }