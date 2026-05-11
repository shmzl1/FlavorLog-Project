# backend/app/algorithms/multimodal/audio_align.py
from typing import List, Dict, Any

class MultimodalAligner:
    """
    【多模态音视频时间轴对齐引擎】
    作用：
    视频处理中，视觉（画面）和听觉（语音）是两条独立的轨道。
    当用户用手机扫视餐桌并说“这盘西兰花是200克”时，语音的时间点和画面出现的时间点往往有轻微错位。
    该类通过时间容差（Time Window Intersection）算法，将视觉识别结果与语音识别结果强绑定。
    """
    def __init__(self, time_tolerance: float = 2.5):
        """
        初始化对齐器
        Args:
            time_tolerance (float): 时间容差（秒）。
            例如设为 2.5 秒，意味着如果画面在第 5 秒出现，那么在 2.5~7.5 秒内说的话，都会被关联到这个画面上。
            以此解决人类“边拍边说”或“先拍后说”的延迟问题。
        """
        self.time_tolerance = time_tolerance

    def align_audio_vision(self, keyframes: List[Dict[str, Any]], audio_segments: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        【核心对齐逻辑】
        参数:
            keyframes: 视觉关键帧列表，格式如 [{"timestamp": 5.0, "visual_features": {...}, ...}]
            audio_segments: 语音文本片段列表，格式如 [{"start_time": 4.0, "end_time": 6.0, "text": "吃了一口米饭"}, ...]
            
        返回:
            融合后的多模态数据列表。
        """
        aligned_results = []

        for frame in keyframes:
            frame_time = frame.get("timestamp", 0.0)
            visual_data = frame.get("visual_features", {})
            
            # 寻找在这个关键帧时间窗口内的所有语音片段
            matched_texts = []
            for audio in audio_segments:
                start = audio.get("start_time", 0.0)
                end = audio.get("end_time", 0.0)
                
                # 判断时间是否交叠：语音段的开始或结束，落在了 关键帧时间 +/- 容差 范围内
                if (frame_time - self.time_tolerance) <= end and (frame_time + self.time_tolerance) >= start:
                    matched_texts.append(audio.get("text", "").strip())
            
            # 拼接这段时间内所有的有效语音
            combined_text = " ".join(matched_texts)
            
            aligned_results.append({
                "timestamp": frame_time,
                "visual_data": visual_data,
                "aligned_audio_text": combined_text
            })

        return aligned_results