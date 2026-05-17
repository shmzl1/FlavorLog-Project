# backend/app/api/v1/fridge.py

import os
import shutil
import tempfile
import traceback
from typing import List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from fastapi.concurrency import run_in_threadpool
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.response import StandardResponse, success_response
from app.schemas.fridge import FridgeItem, FridgeItemCreate
from app.services.fridge_service import FridgeService, fridge_service
from app.services.video_scan_service import FoodDetector 

router = APIRouter()

# [get_fridge_items] 处理获取冰箱列表的 GET 请求。
#  它会调用 FridgeService 逻辑层来过滤出当前登录用户的所有食材。
@router.get("/", response_model=StandardResponse[List[FridgeItem]])
def get_fridge_items(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """【R】获取用户冰箱里的所有食材列表"""
    # 【修复点】：方法名更新为 get_items_by_user，与 Service 层保持一致
    items = FridgeService.get_items_by_user(db, user_id=current_user.id)
    return success_response(data=items, msg="获取冰箱食材成功")

# [scan_food_from_video] 是一个复杂的 AI 识别接口。
# 流程：接收视频 -> 流式写入临时文件 -> 调用 YOLO 识别 -> 自动入库存入冰箱。
@router.post("/scan", response_model=StandardResponse[List[FridgeItem]])
async def scan_food_from_video(
    video: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    【食材视频扫描识别接口】
    自动从视频关键帧中提取食材并将其保存到用户的赛博冰箱中。
    """
    content_type = video.content_type
    if content_type is None or not content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="必须上传合法的视频文件")
    
    filename = video.filename or "unknown_video.mp4"
    print(f"========== 收到食材扫描请求: {filename} ==========")

    temp_video_path = ""
    try:
        # 使用 NamedTemporaryFile 处理大文件上传，避免直接占用过多内存导致服务器 OOM
        with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
            shutil.copyfileobj(video.file, tmp)
            temp_video_path = tmp.name
            
        print(f"[1/3] 视频已暂存至: {temp_video_path}")
        
        # 调用 AI 算法模块（FoodDetector）进行视频处理和食材裁剪
        # 使用 run_in_threadpool 保证耗时计算不会卡死 FastAPI 的主事件循环
        food_images = await run_in_threadpool(FoodDetector.process_video_and_crop, temp_video_path)
        
        if not food_images:
            raise HTTPException(status_code=400, detail="AI 未能识别到食材，请尝试对准食物再次录制")

        # 将识别到的每一项食材草稿入库
        new_items = []
        for idx, _ in enumerate(food_images):
            item_in = FridgeItemCreate(
                name=f"自动扫描食材_{idx+1}", 
                category="其他",
                quantity=1.0,
                unit="个",
                expiration_date=None  
            )
            item = FridgeService.create_item(db, obj_in=item_in, user_id=current_user.id)
            new_items.append(item)
            
        print(f"========== ✅ 处理完成: 已录入 {len(new_items)} 种食材 ==========")
        return success_response(data=new_items, msg="视频扫描入库成功")

    except Exception as e:
        print(f"❌ 视频处理链路崩溃:\n{traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"后端 AI 处理失败: {str(e)}")
    finally:
        # 释放磁盘资源，删除临时视频文件
        if temp_video_path and os.path.exists(temp_video_path):
            try:
                os.remove(temp_video_path)
            except Exception as cleanup_err:
                print(f"⚠️ 临时文件清理失败: {cleanup_err}")

# [delete_item] 处理食材删除请求。
@router.delete("/{item_id}", response_model=StandardResponse)
def delete_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """【D】根据 ID 删除冰箱中的食材"""
    FridgeService.delete_item(db, item_id=item_id, user_id=current_user.id)
    return success_response(data=None, msg="食材删除成功")