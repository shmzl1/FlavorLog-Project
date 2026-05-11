# backend/app/services/video_scan_service.py
import cv2
import numpy as np
import os
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
            video_path (str): 本地暂存的视频物理路径
            
        返回:
            List[bytes]: 裁剪好的食材图片二进制列表，供大模型识别
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
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                raise ValueError(f"无法打开视频文件进行处理: {video_path}")

            frame_count = 0
            
            # 3. 逐帧检测
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                    
                # 每隔 15 帧检测一次 (0.5秒)
                if frame_count % 15 == 0:
                    # 4. 运行 YOLOv8，降低置信度阈值到 0.25 提高召回率
                    # classes=range(39, 61) 代表 COCO 中的食物类 (如 bottle, cup, fork, bowl, banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake)
                    results = model(frame, conf=0.25, classes=list(range(39, 61)), verbose=False)
                    
                    if len(results) > 0 and len(results[0].boxes) > 0:
                        # 获取置信度最高的一个框
                        boxes = results[0].boxes
                        best_idx = int(boxes.conf.argmax())
                        best = boxes[best_idx]
                        
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
                
                # 最多取 5 张图片就结束，防止处理时间过长，并且节省大模型 Token
                if len(cropped_images) >= 5: 
                    break
                    
        except Exception as e:
            print(f"❌ 视频处理异常:\n{traceback.format_exc()}")
            raise RuntimeError(f"处理视频时出错: {str(e)}")
            
        finally:
            # 5. 【释放内存】直接 release 即可。
            # 不需要在这里删文件了，文件的生命周期交由上层 API (fridge.py) 在 finally 中去统一控制和删除。
            if cap is not None:
                cap.release()
                
        return cropped_images