from typing import List, Dict, Any

class MultimodalAligner:
    """
    音视频多模态时间戳对齐类。
    
    【作用】
    在用户“边拍边说”录入饮食或食材时，音频流（语音解说）和视觉流（画面内容）是并行的。
    此类通过获取音频中的有效语音段（VAD），将其时间戳与视觉分镜的时间戳进行对齐。
    从而让 AI 知道：“用户在说‘这个苹果很新鲜’的时候，画面上确实拍到了苹果”。
    """

    def __init__(self, time_tolerance: float = 2.0):
        # 对齐的时间容忍度（秒）。语音和画面允许有几秒的误差。
        self.time_tolerance = time_tolerance

    def align_audio_vision(self, keyframes: List[Dict[str, Any]], audio_segments: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        【作用】将语音片段归属到对应的画面关键帧上。
        
        【参数】
        keyframes: [{'timestamp': 1.5, 'image_url': '...', 'visual_features': [...]}]
        audio_segments: [{'start_time': 1.0, 'end_time': 2.5, 'text': '今天中午吃轻食'}]
        """
        aligned_results = []

        for kf in keyframes:
            kf_time = kf.get("timestamp", 0.0)
            matched_texts = []

            for seg in audio_segments:
                start = seg.get("start_time", 0.0)
                end = seg.get("end_time", 0.0)
                
                # 判断语音时间段是否与关键帧时间点重合（加上容差范围）
                if (start - self.time_tolerance) <= kf_time <= (end + self.time_tolerance):
                    matched_texts.append(seg.get("text", ""))

            aligned_record = {
                "timestamp": kf_time,
                "image_url": kf.get("image_url"),
                "visual_data": kf.get("visual_features"),
                "aligned_audio_text": "，".join(matched_texts)
            }
            aligned_results.append(aligned_record)

        return aligned_results