# backend/app/api/v1/fridge.py

import os
import shutil
import tempfile
import traceback
from typing import List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.concurrency import run_in_threadpool
from sqlalchemy.orm import Session

# 全局依赖导入
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.response import StandardResponse, success_response

# 💡 从 Schema 文件里导入这两个类
from app.schemas.fridge import FridgeItem, FridgeItemCreate
from app.services.fridge_service import fridge_service
from app.services.video_scan_service import FoodDetector 

router = APIRouter()

@router.get("/", response_model=StandardResponse[List[FridgeItem]])
def get_fridge_items(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """获取用户冰箱里的所有食材"""
    items = fridge_service.get_user_items(db, user_id=current_user.id)
    return success_response(data=items, msg="获取冰箱食材成功")

@router.post("/scan", response_model=StandardResponse[List[FridgeItem]])
async def scan_food_from_video(
    video: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """接收前端视频 -> YOLO 裁剪食材 -> 自动存入冰箱"""
    print(f"========== 收到食材扫描请求: {video.filename} ==========")
    
    # 严格校验文件类型
    if video.content_type is None or not video.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="必须上传合法的视频文件")

    temp_video_path = ""
    try:
        # 【内存优化】使用流式落盘，防止大视频撑爆服务器内存
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
            shutil.copyfileobj(video.file, tmp)
            temp_video_path = tmp.name
            
        print(f"[1/3] 视频已落盘至临时文件: {temp_video_path}")
        
        # 将 YOLO 运算放入线程池，防止阻塞 FastAPI 主事件循环
        # 注意：这里传给 FoodDetector 的是本地物理路径 temp_video_path
        food_images = await run_in_threadpool(FoodDetector.process_video_and_crop, temp_video_path)
        
        if not food_images:
            raise HTTPException(status_code=400, detail="未检测到清晰的食材或餐具，请对准食物重试。")

        new_items = []
        for idx, _ in enumerate(food_images):
            # 💡 显式地传入 expiration_date=None，匹配 FridgeItemCreate 模型
            item_in = FridgeItemCreate(
                name=f"自动扫描食材_{idx+1}", 
                category="其他",
                quantity=1.0,
                unit="个",
                expiration_date=None  
            )
            item = fridge_service.create_item(db, obj_in=item_in, user_id=current_user.id)
            new_items.append(item)
            
        print("========== ✅ 整个录入流程完美结束！ ==========")
        return success_response(data=new_items, msg="视频扫描入库成功")

    except Exception as e:
        print(f"❌ 流程中断:\n{traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # 无论成功失败，确保清理临时文件，释放磁盘空间
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                os.remove(temp_video_path)
            except Exception:
                pass

@router.delete("/{item_id}", response_model=StandardResponse)
def delete_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """删除冰箱食材"""
    fridge_service.delete_item(db, item_id=item_id, user_id=current_user.id)
    return success_response(data=None, msg="食材删除成功")