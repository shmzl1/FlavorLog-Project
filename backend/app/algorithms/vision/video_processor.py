import cv2
import numpy as np
from typing import List, Tuple

class VideoVisionProcessor:
    """
    视觉算法核心处理类（O(1) 内存优化版）。
    """
    def __init__(self, blur_threshold: float = 100.0, scene_diff_threshold: float = 0.3):
        self.blur_threshold = blur_threshold
        self.scene_diff_threshold = scene_diff_threshold

    def variance_of_laplacian(self, image: np.ndarray) -> float:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) == 3 else image
        return cv2.Laplacian(gray, cv2.CV_64F).var()

    def enhance_image(self, image: np.ndarray) -> np.ndarray:
        gaussian = cv2.GaussianBlur(image, (0, 0), 2.0)
        return cv2.addWeighted(image, 1.5, gaussian, -0.5, 0)

    def extract_scenes_and_keyframes(self, video_path: str) -> List[Tuple[float, np.ndarray]]:
        # 注意：这里的 video_path 必须是服务器上的本地真实文件路径！
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError(f"OpenCV 无法打开视频文件，请检查路径是否为本地绝对路径: {video_path}")

        fps = cap.get(cv2.CAP_PROP_FPS)
        if fps <= 0:
            fps = 30.0 # 兜底默认帧率，防止除以 0

        prev_hist = None
        scenes_keyframes = []
        frame_idx = 0
        
        # O(1) 空间复杂度：只记录当前分镜中最清晰的一帧及其信息
        best_frame_in_scene = None
        best_var_in_scene = -1.0
        best_timestamp_in_scene = 0.0

        while True:
            ret, frame = cap.read()
            if not ret:
                break
                
            # 1. 计算直方图用于判断镜头切换
            hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
            hist = cv2.calcHist([hsv], [0, 1], None, [50, 60], [0, 180, 0, 256])
            cv2.normalize(hist, hist, alpha=0, beta=1, norm_type=cv2.NORM_MINMAX)

            is_new_scene = False
            if prev_hist is not None:
                diff = cv2.compareHist(prev_hist, hist, cv2.HISTCMP_BHATTACHARYYA)
                if diff > self.scene_diff_threshold:
                    is_new_scene = True

            # 2. 镜头切换时的处理：判定并保存上一个分镜最清晰的帧
            if is_new_scene:
                # 只有清晰度达到阈值，才认为是有效关键帧
                if best_frame_in_scene is not None and best_var_in_scene > self.blur_threshold:
                    scenes_keyframes.append((best_timestamp_in_scene, self.enhance_image(best_frame_in_scene)))
                
                # 重置当前分镜状态
                best_frame_in_scene = None
                best_var_in_scene = -1.0

            # 3. 计算当前帧清晰度，如果是当前分镜中最清晰的，则替换记录
            current_var = self.variance_of_laplacian(frame)
            if current_var > best_var_in_scene:
                best_var_in_scene = current_var
                # 必须使用 .copy()，否则内存地址会被 OpenCV 的下一帧覆盖
                best_frame_in_scene = frame.copy() 
                best_timestamp_in_scene = frame_idx / fps

            prev_hist = hist
            frame_idx += 1

        # 4. 视频结束，处理最后一个分镜的残留数据
        if best_frame_in_scene is not None and best_var_in_scene > self.blur_threshold:
            scenes_keyframes.append((best_timestamp_in_scene, self.enhance_image(best_frame_in_scene)))

        cap.release()
        return scenes_keyframes