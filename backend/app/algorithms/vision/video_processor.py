# backend/app/algorithms/vision/video_processor.py
import cv2
import numpy as np
from typing import List, Tuple

class VideoVisionProcessor:
    """
    【视频视觉处理器】 (任务 11, 12, 13)
    作用：负责处理原始视频流的视觉部分。其核心目标是“去芜存菁”。
    在用户使用手机扫视餐桌时，视频中必然包含大量晃动、模糊的过渡帧。
    此类利用数学算法（拉普拉斯方差）剔除模糊帧，提取出清晰、具有代表性的关键帧。
    """
    def __init__(self, blur_threshold: float = 80.0, frame_skip: int = 15):
        """
        初始化处理器参数
        Args:
            blur_threshold: 模糊判定阈值。越低代表容忍越模糊的照片，通常推荐 80-100。
            frame_skip: 抽帧间隔。若视频为 30fps，设为 15 则每秒抽取 2 帧，降低算力开销。
        """
        self.blur_threshold = blur_threshold
        self.frame_skip = frame_skip

    def _is_blurry(self, frame: np.ndarray) -> bool:
        """
        【图像去模糊核心算法】 (任务 13)
        作用：判断当前帧是否因为相机快速移动而导致运动模糊。
        原理：
        1. 将图像转为灰度图。
        2. 使用 OpenCV 的 Laplacian 算子计算图像的二阶导数（边缘梯度）。
        3. 计算方差。如果图片清晰，边缘锐利，方差会很大；如果图片模糊，缺乏边缘，方差会很小。
        """
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        # CV_64F 表示使用 64位浮点数，防止计算溢出
        variance = cv2.Laplacian(gray, cv2.CV_64F).var()
        
        # 若方差小于设定阈值，则判定为模糊
        return variance < self.blur_threshold

    def extract_scenes_and_keyframes(self, video_path: str) -> List[Tuple[float, np.ndarray]]:
        """
        【视频分镜与关键帧抽取】 (任务 11, 12)
        作用：遍历视频帧，跳帧读取，过滤模糊帧，并返回 (时间戳, 图像数组) 的列表。
        
        Args:
            video_path: 视频文件物理路径
            
        Returns:
            List[Tuple[float, np.ndarray]]: 例如 [(0.5, array), (1.0, array)]
        """
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"无法打开视频文件: {video_path}")

        fps = cap.get(cv2.CAP_PROP_FPS)
        if fps == 0:
            fps = 30.0  # 默认降级

        valid_keyframes = []
        frame_count = 0

        while True:
            ret, frame = cap.read()
            if not ret:
                break

            # 1. 抽帧优化：减少无意义的计算 (任务 12 简化版)
            if frame_count % self.frame_skip == 0:
                # 2. 图像去模糊：丢弃质量差的帧 (任务 13)
                if not self._is_blurry(frame):
                    # 计算当前帧对应的视频时间戳（秒）
                    timestamp = frame_count / fps
                    valid_keyframes.append((timestamp, frame))

            frame_count += 1

        cap.release()
        return valid_keyframes