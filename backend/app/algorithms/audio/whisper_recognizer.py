# backend/app/algorithms/audio/whisper_recognizer.py
import whisper
import traceback
from typing import List, Dict, Any

class WhisperASREngine:
    """
    【Whisper 语音识别 (ASR) 核心引擎】
    
    核心作用：
    本类是视频极速录入流水线的“耳朵”。它负责将用户在视频中的语音转化为带有精确时间戳的文本。
    
    技术选型说明：
    使用 OpenAI 开源的 Whisper 模型。相比于传统的 API 调用（如百度/阿里语音），
    本地运行 Whisper 最大的优势是免费、隐私安全，且能直接输出精准的 word/segment 级别时间戳，
    这是后续进行“多模态音视频对齐 (Multimodal Alignment)”的先决条件。
    """

    def __init__(self, model_size: str = "base"):
        """
        【引擎初始化与模型预热】
        作用：在服务启动时将模型加载到内存/显存中，避免每次处理请求时产生冷启动延迟。
        
        Args:
            model_size (str): 模型大小。
                - "tiny" / "base": 速度极快，显存/内存占用小，适合开发调试。
                - "small" / "medium": 准确率较高，适合生产环境。
                - "large": 准确率最高，但需要较好的 GPU 算力。
        """
        print(f"🔄 正在加载 Whisper ASR 模型 ({model_size})，请稍候...")
        try:
            # 内部会自动判断是否有 GPU (CUDA)，有则用 GPU，无则用 CPU
            self.model = whisper.load_model(model_size)
            print(f"✅ Whisper 模型 ({model_size}) 加载完成！")
        except Exception as e:
            print(f"❌ Whisper 模型加载失败: {e}")
            raise RuntimeError(f"ASR 引擎初始化失败: {e}")

    def transcribe_audio(self, audio_path: str, language: str = "zh") -> List[Dict[str, Any]]:
        """
        【核心识别与数据清洗逻辑】
        
        作用：接收音频文件路径，调用底层模型，并清洗出格式化后的时间戳文本段落。
        
        Args:
            audio_path (str): 本地音频或视频文件的绝对路径。
            language (str): 强制指定语言可以提高识别速度和准确率，默认中文 "zh"。
            
        Returns:
            List[Dict]: 结构化数据，严格输出上层流水线需要的格式。
            例如：[{"start_time": 0.0, "end_time": 2.5, "text": "我吃了一口米饭"}, ...]
        """
        try:
            # fp16=False 是为了兼容纯 CPU 环境，如果在 GPU 环境可以去掉或设为 True
            result = self.model.transcribe(audio_path, language=language, fp16=False)
            
            # ==========================================
            # 【防御性编程：修复静态类型检查报错 (类型收窄)】
            # 静态检查器可能认为 result 是字符串，因此报错没有 .get() 属性。
            # 这里强制校验类型，既消除了飘红，又防止了底层模型返回意外结构导致服务崩溃。
            # ==========================================
            if not isinstance(result, dict):
                print("⚠️ Whisper 返回的结果非预期字典格式")
                return []

            structured_segments = []
            
            # 安全地提取 segments 列表
            segments = result.get("segments", [])
            if not isinstance(segments, list):
                segments = []

            for segment in segments:
                # 再次防御：确保列表里的每个元素也是字典
                if not isinstance(segment, dict):
                    continue
                
                # 安全提取并处理文本
                text = segment.get("text", "")
                if isinstance(text, str):
                    text = text.strip()
                else:
                    # 如果意外得到了非字符串类型，强制转换
                    text = str(text).strip()
                
                # 过滤掉无意义的空噪音段
                if not text:
                    continue
                    
                structured_segments.append({
                    "start_time": float(segment.get("start", 0.0)),
                    "end_time": float(segment.get("end", 0.0)),
                    "text": text
                })
                
            return structured_segments
            
        except Exception as e:
            print(f"❌ 音频识别过程中发生异常:\n{traceback.format_exc()}")
            # 容错处理：发生异常时返回空列表，防止整个视频处理流水线崩溃
            return []