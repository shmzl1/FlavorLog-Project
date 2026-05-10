import cv2
import numpy as np
import os
import tempfile
import traceback
from typing import List

class FoodDetector:
    """
    FlavorLog 专属食材检测器
    添加了极致的错误捕获、Windows 临时文件锁死解决方案以及 Tensor 解析修复
    """
    _model = None

    @classmethod
    def _get_model(cls):
        """单例加载 YOLO 模型"""
        if cls._model is None:
            try:
                from ultralytics import YOLO
                
                # 💡 核心修复：直接传文件名，Ultralytics 会自动在当前目录寻找，找不到会自动下载官方权重
                cls._model = YOLO("yolov8n.pt")
                print("✅ YOLO 模型加载成功！")
            except Exception as e:
                print(f"❌ 初始化 YOLO 失败: {e}")
                raise RuntimeError(f"模型加载失败，请检查环境: {e}")
        return cls._model

    @classmethod
    def process_video_and_crop(cls, video_bytes: bytes) -> List[bytes]:
        """
        处理视频，截取食材图片
        """
        # 1. 唤醒模型
        try:
            model = cls._get_model()
        except Exception as e:
            raise e

        cropped_images = []
        tmp_path = ""
        cap = None
        
        try:
            # 2. 安全写入临时文件 (delete=False 是解决 Windows 崩溃的关键！)
            with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
                tmp.write(video_bytes)
                tmp_path = tmp.name

            # 3. 使用 OpenCV 读取
            cap = cv2.VideoCapture(tmp_path)
            if not cap.isOpened():
                raise ValueError("OpenCV 无法读取视频文件，视频可能损坏或格式不支持")

            frame_count = 0
            # 4. 开始抽帧
            while cap.isOpened():
                ret, frame = cap.read()
                if not ret: 
                    break
                
                # 每隔 15 帧处理一次，减轻 CPU 压力，防止卡死
                if frame_count % 15 == 0:
                    results = model(frame, verbose=False)[0]
                    
                    # 💡 核心修复：必须使用 .item() 将 PyTorch Tensor 转换为纯 Python 数值进行比较
                    food_boxes = [
                        b for b in results.boxes 
                        if int(b.cls.item()) in range(39, 61) and float(b.conf.item()) > 0.4
                    ]
                    
                    if food_boxes:
                        # 获取置信度最高的框
                        best = max(food_boxes, key=lambda b: float(b.conf.item()))
                        
                        # 💡 核心修复：使用 .tolist() 安全地解析坐标数组
                        x1, y1, x2, y2 = map(int, best.xyxy[0].tolist())
                        
                        # 向外扩展 20 像素，防止切掉边缘
                        h, w = frame.shape[:2]
                        p = 20 
                        y1_pad, y2_pad = max(0, y1-p), min(h, y2+p)
                        x1_pad, x2_pad = max(0, x1-p), min(w, x2+p)
                        
                        crop = frame[y1_pad:y2_pad, x1_pad:x2_pad]
                        
                        # 转换并保存
                        success, buf = cv2.imencode(".jpg", crop, [cv2.IMWRITE_JPEG_QUALITY, 90])
                        if success:
                            cropped_images.append(buf.tobytes())
                
                frame_count += 1
                
                # 最多取 5 张图片就结束，防止处理时间过长
                if len(cropped_images) >= 5: 
                    break
                    
        except Exception as e:
            print(f"❌ 视频处理异常:\n{traceback.format_exc()}")
            raise RuntimeError(f"处理视频时出错: {str(e)}")
            
        finally:
            # 6. 【最关键的一步】无论成功与否，必须释放内存并删除临时文件
            if cap is not None:
                cap.release()
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except Exception as e:
                    print(f"⚠️ 临时文件清理失败，但不影响主流程: {e}")
                    
        return cropped_images