# backend/app/services/video_entry_service.py

from typing import List
from app.algorithms.vision.video_processor import VideoVisionProcessor
from app.algorithms.vision.yolo_detector import YoloFoodDetector
from app.algorithms.llm.standardizer import RecordStandardizer
from app.schemas.food_record import FoodRecordCreate

class VideoEntryService:
    """
    视频极速录入总控服务
    作用：串联“视频分镜提取 -> YOLO目标检测 -> 数据标准化”完整流程
    """
    def __init__(self):
        # 实例化算法组件
        self.video_processor = VideoVisionProcessor()
        # 确保你的根目录下有 models/yolov8n.pt 文件
        self.detector = YoloFoodDetector(model_path="models/yolov8n.pt") 
        self.standardizer = RecordStandardizer()

    def process_fast_video_entry(self, local_video_path: str) -> List[FoodRecordCreate]:
        """
        处理视频极速录入的核心流程
        """
        # 1. 视频抽帧与去模糊，获取高质量关键帧 (scenes 为 List[Tuple[float, np.ndarray]])
        scenes = self.video_processor.extract_scenes_and_keyframes(local_video_path)
        
        all_detected_records = []
        
        # 2. 对每一个镜头抽出来的关键帧，进行 YOLO 目标检测
        for timestamp, image_array in scenes:
            yolo_result_dict = self.detector.detect_image(image_array)
            
            # 如果该帧没识别到食物，跳过
            if not yolo_result_dict.get("foods"):
                continue
                
            # 3. 将 AI 原始结果标准化为后端 Pydantic 模型
            food_record_schema = self.standardizer.ai_result_to_food_record(yolo_result_dict)
            
            # 补充信息：记录来源和时间点描述
            food_record_schema.source_type = "video_ai"
            food_record_schema.description = f"{food_record_schema.description} (识别自视频 {timestamp:.1f}s 处)"
            
            all_detected_records.append(food_record_schema)

        return all_detected_records