# backend/app/services/video_scan_service.py
import cv2
import numpy as np
import os
import traceback
from typing import List

class FoodDetector:
    """
    FlavorLog 专属食材检测器
    
    核心作用：
    接收视频文件路径，利用 YOLOv8 模型识别画面中的食材，并将其裁剪为单张图片二进制流，
    以便后续喂给大模型进行精细化识别。
    """
    _model = None

    @classmethod
    def _get_model(cls):
        """单例加载 YOLO 模型"""
        if cls._model is None:
            try:
                from ultralytics import YOLO
                # 💡 确保模型路径正确，如果你的权重文件在 models 文件夹下，请加上路径前缀
                cls._model = YOLO("models/yolov8n.pt")
                print("✅ YOLO 模型加载成功！")
            except Exception as e:
                print(f"❌ 初始化 YOLO 失败: {e}")
                raise RuntimeError(f"模型加载失败，请检查环境: {e}")
        return cls._model

    @classmethod
    def process_video_and_crop(cls, video_path: str) -> List[bytes]:
        """
        处理视频，截取食材图片
        
        参数:
            video_path (str): 外部传入的视频物理路径（字符串类型）
            
        返回:
            List[bytes]: 裁剪出的食材图片二进制列表
        """
        # 1. 唤醒模型
        try:
            model = cls._get_model()
        except Exception as e:
            raise e

        cropped_images = []
        cap = None
        
        try:
            # 2. 直接使用 OpenCV 读取传进来的视频路径
            # 💡 修复点：这里不再接收 bytes，不再手动写临时文件，性能更优
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                raise ValueError(f"OpenCV 无法读取视频文件: {video_path}")

            frame_count = 0
            
            # 3. 逐帧检测并抽帧
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                    
                # 每隔 15 帧处理一次 (约 0.5秒)
                if frame_count % 15 == 0:
                    # 运行 YOLOv8 检测
                    results = model(frame, verbose=False)[0]
                    
                    # 4. 筛选 COCO 数据集中的食物类 (39~60)
                    food_boxes = [
                        b for b in results.boxes 
                        if int(b.cls.item()) in range(39, 61) and float(b.conf.item()) > 0.4
                    ]
                    
                    if food_boxes:
                        # 获取置信度最高的一个框
                        best = max(food_boxes, key=lambda b: float(b.conf.item()))
                        
                        # 💡 核心修复：解析坐标
                        x1, y1, x2, y2 = map(int, best.xyxy[0].tolist())
                        
                        # 向外扩展 20 像素，防止切掉边缘
                        h, w = frame.shape[:2]
                        p = 20 
                        y1_pad, y2_pad = max(0, y1-p), min(h, y2+p)
                        x1_pad, x2_pad = max(0, x1-p), min(w, x2+p)
                        
                        crop = frame[y1_pad:y2_pad, x1_pad:x2_pad]
                        
                        # 5. 编码为 JPEG 二进制流
                        success, buf = cv2.imencode(".jpg", crop, [cv2.IMWRITE_JPEG_QUALITY, 90])
                        if success:
                            cropped_images.append(buf.tobytes())
                
                frame_count += 1
                
                # 最多取 5 张图片就结束，防止处理时间过长，并且节省后续 API 的 Token
                if len(cropped_images) >= 5: 
                    break
                    
        except Exception as e:
            print(f"❌ 视频处理异常:\n{traceback.format_exc()}")
            raise RuntimeError(f"处理视频时出错: {str(e)}")
            
        finally:
            # 6. 【资源释放】
            # 💡 注意：由于文件是在 API 层（fridge.py）创建的，
            # 文件的物理删除也由 API 层控制，这里只负责释放 OpenCV 对象。
            if cap is not None:
                cap.release()
                
        return cropped_images