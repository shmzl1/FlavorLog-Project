# backend/app/tasks/video_tasks.py
import os
from app.core.celery_app import celery_app
from app.services.video_entry_service import VideoEntryService

# 全局单例，确保每个 Celery 子进程只持有一份模型实例
_video_service = None

def get_video_service():
    global _video_service
    if _video_service is None:
        _video_service = VideoEntryService()
    return _video_service

@celery_app.task(bind=True)
def process_video_async_task(self, video_path: str, user_id: int):
    """
    【Celery 异步视频处理 Worker】
    
    接收 FastAPI 抛过来的视频文件路径，执行极度耗时的 AI 流水线。
    """
    # 1. 随时更新进度状态，让前端知道现在跑到了哪一步
    self.update_state(state='PROCESSING', meta={'progress': '正在加载并预热 AI 模型...'})
    
    service = get_video_service()
    
    try:
        self.update_state(state='PROCESSING', meta={'progress': '正在进行多模态 AI 视听解析...'})
        
        # 2. 执行沉重的 AI 流水线 (调用你之前传给我的 service 代码)
        records = service.process_fast_video_entry(video_path)
        
        # 3. 执行垃圾回收，清空 CUDA 缓存
        service.release_resources()
        
        # 4. 清理前端上传的临时原视频文件
        if os.path.exists(video_path):
            os.remove(video_path)
            
        # 5. 返回结果 (Celery 会自动把这个字典序列化为 JSON 存入 Redis)
        serialized_records = [r.model_dump() for r in records]
        return {"status": "success", "data": serialized_records, "user_id": user_id}
        
    except Exception as exc:
        # 处理失败时同样需要释放资源
        service.release_resources()
        self.update_state(state='FAILURE', meta={'exc_type': type(exc).__name__, 'exc_message': str(exc)})
        raise exc