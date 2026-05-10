import os
from datetime import datetime
from time import perf_counter
from uuid import uuid4

from sqlalchemy.orm import Session

from app.core.config import settings
from app.algorithms.llm.llm_client import LLMClient
from app.algorithms.ocr.menu_ocr import OCRRuntimeError, extract_text, parse_menu_names
from app.algorithms.ranking.recipe_ranker import rank_recommendations
from app.models.ai_task import AIAnalysisLog
from app.models.ai_task import AITask
from app.models.ai_task import RecipeRecommendation
from app.schemas.recommendation import (
    MenuScanRequest,
    RecommendationRecipeRequest,
)
from app.services.upload_service import UploadService


class RecommendationService:
    @staticmethod
    def _new_task_id() -> str:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"task_{ts}_{uuid4().hex[:6]}"

    @staticmethod
    def submit_recipe_recommendation(
        db: Session, *, user_id: int, payload: RecommendationRecipeRequest
    ) -> AITask:
        task = AITask(
            task_id=RecommendationService._new_task_id(),
            user_id=user_id,
            task_type="recipe_recommendation",
            status="pending",
            input_json=payload.model_dump(),
            result_json={},
        )
        db.add(task)
        db.commit()
        db.refresh(task)

        return task

    @staticmethod
    def get_task(db: Session, *, user_id: int, task_id: str) -> AITask | None:
        task = (
            db.query(AITask)
            .filter(AITask.task_id == task_id, AITask.user_id == user_id)
            .first()
        )
        if not task:
            return None
        if task.status != "pending":
            return task

        RecommendationService._run_pending_task(db, user_id=user_id, task=task)
        return task

    @staticmethod
    def _safe_input_json(task: AITask) -> dict:
        return task.input_json if isinstance(task.input_json, dict) else {}

    @staticmethod
    def _append_log(
        db: Session,
        *,
        user_id: int,
        task_id: str | None,
        provider: str,
        model_name: str,
        prompt_summary: str,
        input_json: dict,
        output_json: dict,
        latency_ms: int,
        success: bool,
        error_message: str | None,
    ) -> None:
        log = AIAnalysisLog(
            user_id=user_id,
            task_id=task_id,
            provider=provider,
            model_name=model_name,
            prompt_summary=prompt_summary,
            input_json=input_json,
            output_json=output_json,
            latency_ms=latency_ms,
            success=success,
            error_message=error_message,
        )
        db.add(log)

    @staticmethod
    def _extract_recs(output_json: dict) -> list[dict]:
        recs = output_json.get("recommendations") or []
        if isinstance(recs, list):
            return [x for x in recs if isinstance(x, dict)]
        return []

    @staticmethod
    def _persist_recs(db: Session, *, user_id: int, task_id: str, recs: list[dict]) -> None:
        for r in recs:
            rec = RecipeRecommendation(
                user_id=user_id,
                task_id=task_id,
                title=r.get("title") or "推荐食谱",
                description=None,
                recipe_type="recommendation",
                ingredients_json=[],
                steps_json=[],
                nutrition_json=r.get("nutrition") or {},
                score=r.get("score"),
                reason=r.get("reason"),
            )
            db.add(rec)

    @staticmethod
    def _run_pending_task(db: Session, *, user_id: int, task: AITask) -> None:
        task.status = "running"
        db.add(task)
        db.commit()
        db.refresh(task)

        client = LLMClient.from_settings(settings)
        start = perf_counter()
        input_json = RecommendationService._safe_input_json(task)
        try:
            result = client.generate_recommendations(input_json)
            latency_ms = int((perf_counter() - start) * 1000)

            recs = []
            if isinstance(result.output_json, dict):
                recs = RecommendationService._extract_recs(result.output_json)
                if recs and input_json:
                    recs = rank_recommendations(input_json, recs)
                    result.output_json["recommendations"] = recs

            RecommendationService._append_log(
                db,
                user_id=user_id,
                task_id=task.task_id,
                provider=client.provider,
                model_name=client.model,
                prompt_summary=result.prompt_summary,
                input_json=input_json,
                output_json=result.output_json if isinstance(result.output_json, dict) else {},
                latency_ms=latency_ms,
                success=True,
                error_message=None,
            )
            RecommendationService._persist_recs(db, user_id=user_id, task_id=task.task_id, recs=recs)

            task.status = "success"
            task.result_json = result.output_json if isinstance(result.output_json, dict) else {}
            db.add(task)
            db.commit()
            db.refresh(task)
        except Exception as e:
            latency_ms = int((perf_counter() - start) * 1000)
            RecommendationService._append_log(
                db,
                user_id=user_id,
                task_id=task.task_id,
                provider=client.provider,
                model_name=client.model,
                prompt_summary="error:recommendations",
                input_json=input_json,
                output_json={},
                latency_ms=latency_ms,
                success=False,
                error_message=str(e),
            )
            task.status = "failed"
            task.error_message = str(e)
            db.add(task)
            db.commit()
            db.refresh(task)

    @staticmethod
    def menu_scan(db: Session, *, user_id: int, payload: MenuScanRequest) -> dict:
        file_url, abs_path = RecommendationService._resolve_uploaded_path(
            db, user_id=user_id, file_id=payload.file_id
        )

        start = perf_counter()
        provider = (settings.OCR_PROVIDER or "mock").lower()
        timeout = int(getattr(settings, "OCR_TIMEOUT_SECONDS", 30))
        try:
            text = extract_text(abs_path, provider=provider, timeout_seconds=timeout)
        except OCRRuntimeError as e:
            raise ValueError(str(e))

        names = parse_menu_names(text) or ["炸鸡排饭", "番茄牛肉饭"]
        menu_items, best_choice = RecommendationService._build_menu_scan_result(
            names, health_goal=payload.health_goal, avoid_ingredients=payload.avoid_ingredients or []
        )

        latency_ms = int((perf_counter() - start) * 1000)
        RecommendationService._append_log(
            db,
            user_id=user_id,
            task_id=None,
            provider=provider,
            model_name="mock",
            prompt_summary="menu_scan",
            input_json={
                "file_id": payload.file_id,
                "file_url": file_url,
                "health_goal": payload.health_goal,
                "avoid_ingredients": payload.avoid_ingredients,
            },
            output_json={"menu_items": menu_items, "best_choice": best_choice, "raw_text": text},
            latency_ms=latency_ms,
            success=True,
            error_message=None,
        )
        db.commit()
        return {"menu_items": menu_items, "best_choice": best_choice}

    @staticmethod
    def _resolve_uploaded_path(db: Session, *, user_id: int, file_id: int) -> tuple[str, str]:
        uploaded = UploadService.get_by_id(db, user_id=user_id, file_id=file_id)
        if not uploaded:
            raise ValueError("file_id 不存在或无权访问")
        file_url = uploaded.file_url or ""
        if not file_url.startswith("/uploads/"):
            raise ValueError("file_url 不合法")

        rel_path = file_url.lstrip("/").replace("/", os.sep)
        backend_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        abs_path = os.path.join(backend_root, rel_path)
        if not os.path.exists(abs_path):
            raise ValueError("文件不存在")
        return file_url, abs_path

    @staticmethod
    def _score_menu_item(
        name: str, *, avoid_set: set[str], health_goal: str | None
    ) -> tuple[str, str, float]:
        n = (name or "").strip()
        if not n:
            return ("red", "信息不足，建议结合分量与烹饪方式选择", 0.0)
        if any(x and x in n for x in avoid_set):
            return ("red", "包含忌口食材", 0.05)

        protein_kw = ["鸡胸", "鸡蛋", "牛肉", "鱼", "虾", "豆腐", "瘦肉", "里脊", "鸡腿", "蛋白"]
        veg_kw = ["西兰花", "青菜", "菠菜", "生菜", "黄瓜", "番茄", "菌", "芦笋", "海带", "紫菜", "玉米"]
        high_fat_kw = ["炸", "油炸", "奶油", "芝士", "肥肠", "五花", "培根", "烧烤", "烤肉", "干锅", "红烧"]
        high_sugar_kw = ["奶茶", "可乐", "甜品", "蛋糕", "冰淇淋", "糖"]
        high_carb_kw = ["面", "粉", "米饭", "炒饭", "盖饭", "粥", "馒头", "饼", "披萨", "汉堡", "薯条"]
        light_kw = ["清蒸", "水煮", "白灼", "凉拌", "清炒", "炖", "汤", "沙拉"]

        score = 0.6
        reasons: list[str] = []

        if any(k in n for k in protein_kw):
            score += 0.25
            reasons.append("蛋白质更友好")
        if any(k in n for k in veg_kw):
            score += 0.15
            reasons.append("蔬菜搭配更均衡")
        if any(k in n for k in light_kw):
            score += 0.1
            reasons.append("烹饪方式更清淡")

        if any(k in n for k in high_sugar_kw):
            score -= 0.35
            reasons.append("含糖/甜品不利于健康目标")
        if any(k in n for k in high_fat_kw):
            score -= 0.35
            reasons.append("油脂较高需谨慎")
        if any(k in n for k in high_carb_kw):
            score -= 0.1
            reasons.append("碳水偏高需控制分量")

        goal = health_goal
        if goal == "lose_fat":
            if any(k in n for k in high_fat_kw + high_sugar_kw):
                score -= 0.2
                reasons.append("不利于减脂目标")
            if any(k in n for k in light_kw + protein_kw + veg_kw):
                score += 0.05
        elif goal == "gain_muscle":
            if any(k in n for k in protein_kw):
                score += 0.1
                reasons.append("更贴合增肌目标")
            if any(k in n for k in high_sugar_kw):
                score -= 0.1
        elif goal == "healthy":
            if any(k in n for k in high_sugar_kw + high_fat_kw):
                score -= 0.1
            if any(k in n for k in veg_kw + light_kw):
                score += 0.05

        score = max(0.0, min(1.0, score))
        if score >= 0.8:
            level = "green"
        elif score >= 0.5:
            level = "yellow"
        else:
            level = "red"

        reason = "；".join(reasons) if reasons else "信息不足，建议结合分量与烹饪方式选择"
        return (level, reason, score)

    @staticmethod
    def _build_menu_scan_result(
        names: list[str],
        *,
        health_goal: str | None,
        avoid_ingredients: list[str],
    ) -> tuple[list[dict], str]:
        avoid_set = set(avoid_ingredients or [])
        scored: list[tuple[float, str, str, str]] = []
        for n in (names or [])[:10]:
            level, reason, score = RecommendationService._score_menu_item(
                n, avoid_set=avoid_set, health_goal=health_goal
            )
            scored.append((score, n, level, reason))

        menu_items = [{"name": n, "level": level, "reason": reason} for (_, n, level, reason) in scored]
        scored.sort(reverse=True)

        best_choice = ""
        for s, n, level, _ in scored:
            if level != "red" and n:
                best_choice = n
                break
        if not best_choice and scored:
            best_choice = scored[0][1]
        if not best_choice and names:
            best_choice = names[0]
        return menu_items, best_choice

    @staticmethod
    def list_saved_recipes(
        db: Session,
        *,
        user_id: int,
        page: int = 1,
        page_size: int = 10,
        recipe_type: str | None = None,
        task_id: str | None = None,
    ) -> tuple[list[RecipeRecommendation], dict]:
        page = max(int(page), 1)
        page_size = min(max(int(page_size), 1), 50)

        q = db.query(RecipeRecommendation).filter(RecipeRecommendation.user_id == user_id)
        if recipe_type:
            q = q.filter(RecipeRecommendation.recipe_type == recipe_type)
        if task_id:
            q = q.filter(RecipeRecommendation.task_id == task_id)

        total = q.count()
        total_pages = (total + page_size - 1) // page_size
        offset = (page - 1) * page_size

        items = (
            q.order_by(RecipeRecommendation.created_at.desc())
            .offset(offset)
            .limit(page_size)
            .all()
        )

        pagination = {
            "page": page,
            "page_size": page_size,
            "total": total,
            "total_pages": total_pages,
            "has_next": page < total_pages,
        }
        return items, pagination

    @staticmethod
    def get_saved_recipe(
        db: Session, *, user_id: int, recipe_id: int
    ) -> RecipeRecommendation | None:
        return (
            db.query(RecipeRecommendation)
            .filter(RecipeRecommendation.id == recipe_id, RecipeRecommendation.user_id == user_id)
            .first()
        )

    @staticmethod
    def get_dashboard(db: Session, *, user_id: int) -> dict:
        latest_menu_scan = (
            db.query(AIAnalysisLog)
            .filter(AIAnalysisLog.user_id == user_id, AIAnalysisLog.prompt_summary == "menu_scan")
            .order_by(AIAnalysisLog.created_at.desc())
            .first()
        )

        latest_recommendations = (
            db.query(RecipeRecommendation)
            .filter(RecipeRecommendation.user_id == user_id, RecipeRecommendation.recipe_type == "recommendation")
            .order_by(RecipeRecommendation.created_at.desc())
            .limit(3)
            .all()
        )

        latest_fridge_recipes = (
            db.query(RecipeRecommendation)
            .filter(RecipeRecommendation.user_id == user_id, RecipeRecommendation.recipe_type != "recommendation")
            .order_by(RecipeRecommendation.created_at.desc())
            .limit(3)
            .all()
        )

        return {
            "latest_menu_scan": latest_menu_scan.output_json if latest_menu_scan else None,
            "latest_recommendations": latest_recommendations,
            "latest_fridge_recipes": latest_fridge_recipes,
        }
