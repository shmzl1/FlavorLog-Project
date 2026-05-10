# backend/app/services/video_entry_service.py
import os
import uuid
import json
import traceback
from typing import List, Dict, Any

# 注意：根据你使用的 moviepy 版本，导入方式可能是 from moviepy.editor import VideoFileClip 
# 或者 from moviepy import VideoFileClip。这里以你提供的格式为准。
from moviepy import VideoFileClip

from app.algorithms.vision.video_processor import VideoVisionProcessor
from app.algorithms.vision.yolo_detector import YoloFoodDetector
from app.algorithms.multimodal.audio_align import MultimodalAligner
from app.algorithms.llm.standardizer import RecordStandardizer
from app.schemas.food_record import FoodRecordCreate

# 引入真实的 Whisper 引擎
from app.algorithms.audio.whisper_recognizer import WhisperASREngine 


class VideoEntryService:
    """
    【视频极速录入流水线编排服务】
    
    核心作用：
    作为整个“极速录入”功能的总指挥，负责串联所有的底层 AI 算法。
    流水线顺序：听觉提取(Whisper) -> 视觉抽帧(OpenCV) -> 视觉检测(YOLO) -> 时空对齐(Aligner) -> 数据清洗与组装(Standardizer)。
    """

    def __init__(self):
        """
        【服务初始化】
        预加载所有 AI 算法模型，避免在每次处理请求时重复加载产生的冷启动延迟。
        """
        self.video_processor = VideoVisionProcessor()
        self.detector = YoloFoodDetector(model_path="models/yolov8n.pt") 
        self.aligner = MultimodalAligner(time_tolerance=2.5)   
        self.standardizer = RecordStandardizer()
        
        # 实例化真正的语音识别引擎 (开发阶段用 base，保证速度；上线生产环境可换为 small)
        self.asr_engine = WhisperASREngine(model_size="base")

    def _extract_and_recognize_audio(self, video_path: str) -> List[Dict[str, Any]]:
        """
        【真实音频抽取与识别】
        
        作用：
        1. 使用 moviepy 将视频中的音频轨道剥离出来，保存为临时 .wav 文件。
        2. 将纯音频投递给本地的 Whisper 模型进行识别，提取出带有精确时间戳的结构化语音段落。
        3. 识别完成后，立刻销毁临时音频文件，防止服务器磁盘被临时文件占满。
        
        Args:
            video_path (str): 本地视频文件的绝对路径
            
        Returns:
            List[Dict]: 识别出来的语音段落列表，例如 [{"start_time": 0.0, "end_time": 2.5, "text": "..."}]
        """
        # 使用 uuid 生成唯一的临时音频文件名，避免并发请求时发生文件覆写冲突
        temp_audio_path = f"uploads/temp_{uuid.uuid4().hex}.wav"
        
        try:
            # 1. 抽取音频
            print(f"🎬 正在从视频中剥离音频轨道...")
            with VideoFileClip(video_path) as video_clip:
                if video_clip.audio is None:
                    print("⚠️ 视频中未检测到音频轨道。")
                    return []
                # 写入临时音频文件，禁用啰嗦的日志输出
                video_clip.audio.write_audiofile(temp_audio_path, logger=None)
            
            # 2. 调用真实的 Whisper 模型进行识别
            print(f"🎙️ 正在进行 AI 语音识别...")
            segments = self.asr_engine.transcribe_audio(temp_audio_path)
            print(f"✅ 语音识别完成，共识别到 {len(segments)} 段有效语音。")
            
            return segments
            
        except Exception as e:
            print(f"❌ 语音抽取或识别失败: {e}\n{traceback.format_exc()}")
            # 防御性编程：失败时返回空列表，不要抛出异常导致整个流水线阻断
            return []
            
        finally:
            # 3. 无论成功与否，必须清理临时文件
            if os.path.exists(temp_audio_path):
                try:
                    os.remove(temp_audio_path)
                except OSError:
                    pass

    def process_fast_video_entry(self, local_video_path: str) -> List[FoodRecordCreate]:
        """
        【视频极速录入核心编排引擎】
        
        核心作用：
        将用户上传的原始视频，通过多模态 AI 转化为结构化、可直接落库的饮食记录 Schema。
        
        容错机制：
        全路径采用 try-except 保护，即使某几帧画面识别失败，或者解析脏数据抛出异常，
        也能保证流水线平稳运行，并在最终的异常路径兜底返回空列表。
        
        Args:
            local_video_path (str): 待处理视频的本地路径
            
        Returns:
            List[FoodRecordCreate]: 结构化数据列表，所有代码路径均须保证返回此类型
        """
        try:
            # 1. 抽取并识别音频 (真实的 Whisper 模型调用)
            audio_segments = self._extract_and_recognize_audio(local_video_path)
            
            # 2. 视频切镜与关键帧抽取
            scenes = self.video_processor.extract_scenes_and_keyframes(local_video_path)
            
            # 3. 遍历关键帧进行视觉特征检测
            raw_keyframes_data: List[Dict[str, Any]] = []
            for timestamp, image_array in scenes:
                # 调用 YOLO 视觉检测
                yolo_result = self.detector.detect_image(image_array)
                
                # ==========================================
                # 【防御性编程：解决 "str" 没有 "get" 属性的静态检查报错】
                # 有时底层算法（或大模型）可能直接返回了 JSON 字符串，这里将其强制解析为 dict
                # ==========================================
                if isinstance(yolo_result, str):
                    try:
                        yolo_result = json.loads(yolo_result)
                    except json.JSONDecodeError:
                        yolo_result = {} # 解析失败则给一个空字典兜底
                
                # 只有确认 yolo_result 是字典，才安全地调用 .get()
                if isinstance(yolo_result, dict) and yolo_result.get("foods"):
                    raw_keyframes_data.append({
                        "timestamp": timestamp,
                        "visual_features": yolo_result,
                        "image_array": image_array
                    })
                    
            # 4. 多模态音视频时间轴对齐 (根据时间戳将语音和画面绑定)
            aligned_results = self.aligner.align_audio_vision(raw_keyframes_data, audio_segments)
            
            # 5. 组装并清洗为最终的 Pydantic Schema
            all_detected_records: List[FoodRecordCreate] = []
            for aligned_item in aligned_results:
                
                # 再次防御性校验：确保 visual_data 取出来确实是字典
                yolo_result_dict = aligned_item.get("visual_data")
                if not yolo_result_dict or not isinstance(yolo_result_dict, dict):
                    continue
                    
                speech_text = aligned_item.get("aligned_audio_text", "")
                timestamp = aligned_item.get("timestamp", 0.0)
                
                # 将杂乱的视觉字典标准化出结构严谨的 FoodRecordCreate 对象
                food_record_schema = self.standardizer.ai_result_to_food_record(yolo_result_dict)
                
                # 补充多模态描述信息
                desc = f"画面出现于视频 {timestamp:.1f}s 处。"
                if speech_text:
                    desc += f" 语音描述: '{speech_text}'"
                    
                food_record_schema.source_type = "video_multimodal"
                food_record_schema.description = desc
                
                all_detected_records.append(food_record_schema)
                
            # 【正常返回路径】：返回识别出的标准 Schema 列表
            return all_detected_records
            
        except Exception as e:
            # 记录详细的崩溃堆栈，方便后端查错
            print(f"❌ 视频处理流水线发生致命异常: {e}\n{traceback.format_exc()}")
            
            # ==========================================
            # 【兜底返回路径：解决 "必须在所有代码路径上返回值" 的报错】
            # 当发生不可预知的异常时，严禁让函数隐式返回 None，必须返回空列表 []，
            # 从而严格遵守 List[FoodRecordCreate] 的类型签名承诺。
            # ==========================================
            return []