# backend/app/services/video_entry_service.py
import os
import gc
import json
import torch
import traceback
from typing import List, Dict, Any

# 注意：根据环境不同，可能是 from moviepy.editor import VideoFileClip
from moviepy import VideoFileClip

from app.algorithms.vision.video_processor import VideoVisionProcessor
from app.algorithms.vision.yolo_detector import YoloFoodDetector
from app.algorithms.multimodal.audio_align import MultimodalAligner
from app.algorithms.llm.standardizer import RecordStandardizer
from app.algorithms.audio.whisper_recognizer import WhisperASREngine
from app.schemas.food_record import FoodRecordCreate

class VideoEntryService:
    """
    【视频极速录入流水线编排服务】
    作用：串联抽帧、YOLO视觉检测、Whisper语音识别、音视频对齐与大模型标准化。
    
    设计说明：
    采用了“模型懒加载”策略。只有在真正开始处理视频时，才会加载大模型到显存，
    处理结束后可以通过 release_resources 主动释放。
    """
    def __init__(self):
        # 初始化占位，不立刻加载模型
        self._video_processor = None
        self._detector = None
        self._aligner = None
        self._standardizer = None
        self._asr_engine = None

    # --- 懒加载属性定义 ---
    @property
    def video_processor(self):
        if self._video_processor is None:
            self._video_processor = VideoVisionProcessor()
        return self._video_processor

    @property
    def detector(self):
        if self._detector is None:
            self._detector = YoloFoodDetector(model_path="models/yolov8n.pt")
        return self._detector

    @property
    def asr_engine(self):
        if self._asr_engine is None:
            self._asr_engine = WhisperASREngine(model_size="base")
        return self._asr_engine

    @property
    def aligner(self):
        if self._aligner is None:
            self._aligner = MultimodalAligner(time_tolerance=2.5)
        return self._aligner

    @property
    def standardizer(self):
        if self._standardizer is None:
            self._standardizer = RecordStandardizer()
        return self._standardizer

    def release_resources(self):
        """
        【主动资源释放方法】 (解决你报错的关键点)
        作用：清空 PyTorch 的 CUDA 缓存并触发 Python 垃圾回收，防止显存泄漏。
        """
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        gc.collect()
        print("♻️ 已执行显存清理与垃圾回收")

    def process_fast_video_entry(self, local_video_path: str) -> List[FoodRecordCreate]:
        """【视频处理主逻辑流水线】"""
        try:
            # 1. 语音识别
            audio_segments = self.asr_engine.transcribe_audio(local_video_path)
            
            # 2. 视觉抽帧
            scenes = self.video_processor.extract_scenes_and_keyframes(local_video_path)
            
            # 3. 视觉特征提取
            raw_keyframes_data = []
            for timestamp, image_array in scenes:
                yolo_result = self.detector.detect_image(image_array)
                
                # 防御性解析字符串/字典
                if isinstance(yolo_result, str):
                    try: yolo_result = json.loads(yolo_result)
                    except: yolo_result = {}
                
                if isinstance(yolo_result, dict) and yolo_result.get("foods"):
                    raw_keyframes_data.append({
                        "timestamp": timestamp,
                        "visual_features": yolo_result,
                        "image_array": image_array
                    })
                    
            # 4. 音视频对齐
            aligned_results = self.aligner.align_audio_vision(raw_keyframes_data, audio_segments)
            
            # 5. 标准化
            all_detected_records = []
            for aligned_item in aligned_results:
                yolo_dict = aligned_item.get("visual_data")
                if not yolo_dict or not isinstance(yolo_dict, dict):
                    continue
                
                food_record = self.standardizer.ai_result_to_food_record(yolo_dict)
                food_record.source_type = "video_multimodal"
                
                speech = aligned_item.get("aligned_audio_text", "")
                ts = aligned_item.get("timestamp", 0.0)
                food_record.description = f"视频 {ts:.1f}s 识别。语音: {speech}" if speech else f"视频 {ts:.1f}s 识别"
                
                all_detected_records.append(food_record)
                
            return all_detected_records
            
        except Exception as e:
            print(f"❌ 视频流处理失败: {e}\n{traceback.format_exc()}")
            return []