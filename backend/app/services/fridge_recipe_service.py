from datetime import datetime
from time import perf_counter
from uuid import uuid4

from sqlalchemy.orm import Session

from app.algorithms.llm.llm_client import LLMClient
from app.core.config import settings
from app.models.ai_task import AITask, RecipeRecommendation
from app.models.ai_task import AIAnalysisLog
from app.models.fridge_item import FridgeItem
from app.schemas.fridge_recipe_task import (
    FridgeRecipeTaskRequest,
    FridgeRecipeTaskResult,
)


class FridgeRecipeService:
    @staticmethod
    def _new_task_id() -> str:
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"task_{ts}_{uuid4().hex[:6]}"

    @staticmethod
    def submit_task(db: Session, *, user_id: int, payload: FridgeRecipeTaskRequest) -> AITask:
        items = db.query(FridgeItem).filter(FridgeItem.user_id == user_id).all()
        input_json = {
            "payload": payload.model_dump(),
            "fridge_items": [
                {
                    "id": x.id,
                    "name": x.name,
                    "category": x.category,
                    "quantity": float(x.quantity) if x.quantity is not None else None,
                    "unit": x.unit,
                    "expiration_date": x.expiration_date.isoformat() if x.expiration_date else None,
                }
                for x in items
            ],
        }

        task = AITask(
            task_id=FridgeRecipeService._new_task_id(),
            user_id=user_id,
            task_type="fridge_recipe",
            status="pending",
            input_json=input_json,
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

        FridgeRecipeService._run_pending_task(db, user_id=user_id, task=task)
        return task

    @staticmethod
    def _serialize_fridge_items(items: list[FridgeItem]) -> list[dict]:
        return [
            {
                "id": x.id,
                "name": x.name,
                "category": x.category,
                "quantity": float(x.quantity) if x.quantity is not None else None,
                "unit": x.unit,
                "expiration_date": x.expiration_date.isoformat() if x.expiration_date else None,
            }
            for x in items
        ]

    @staticmethod
    def _extract_payload(task: AITask) -> FridgeRecipeTaskRequest:
        payload_dict = {}
        if isinstance(task.input_json, dict):
            payload_dict = task.input_json.get("payload") or {}
        return FridgeRecipeTaskRequest.model_validate(payload_dict)

    @staticmethod
    def _append_log(
        db: Session,
        *,
        user_id: int,
        task_id: str,
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
    def _run_pending_task(db: Session, *, user_id: int, task: AITask) -> None:
        task.status = "running"
        db.add(task)
        db.commit()
        db.refresh(task)

        payload = FridgeRecipeService._extract_payload(task)
        items = db.query(FridgeItem).filter(FridgeItem.user_id == user_id).all()
        fridge_items = FridgeRecipeService._serialize_fridge_items(items)

        client = LLMClient.from_settings(settings)
        start = perf_counter()
        try:
            llm = client.generate_fridge_recipe(payload.model_dump(), fridge_items)
            latency_ms = int((perf_counter() - start) * 1000)

            FridgeRecipeService._append_log(
                db,
                user_id=user_id,
                task_id=task.task_id,
                provider=client.provider,
                model_name=client.model,
                prompt_summary=llm.prompt_summary,
                input_json={"payload": payload.model_dump(), "fridge_items": fridge_items},
                output_json=llm.output_json,
                latency_ms=latency_ms,
                success=True,
                error_message=None,
            )

            rec = RecipeRecommendation(
                user_id=user_id,
                task_id=task.task_id,
                title=llm.output_json.get("title") or "推荐菜谱",
                description=llm.output_json.get("description"),
                recipe_type=payload.target,
                ingredients_json=llm.output_json.get("ingredients") or [],
                steps_json=llm.output_json.get("steps") or [],
                nutrition_json=llm.output_json.get("nutrition") or {},
                score=llm.output_json.get("score"),
                reason="基于冰箱食材与目标生成",
            )
            db.add(rec)
            db.commit()
            db.refresh(rec)

            score = rec.score if rec.score is not None else llm.output_json.get("score")
            result = FridgeRecipeTaskResult(
                recipe_id=rec.id,
                title=rec.title,
                description=rec.description,
                ingredients=rec.ingredients_json,
                steps=rec.steps_json,
                nutrition=rec.nutrition_json,
                score=float(score or 0),
            )

            task.status = "success"
            task.result_json = result.model_dump()
            db.add(task)
            db.commit()
            db.refresh(task)
        except Exception as e:
            latency_ms = int((perf_counter() - start) * 1000)
            FridgeRecipeService._append_log(
                db,
                user_id=user_id,
                task_id=task.task_id,
                provider=client.provider,
                model_name=client.model,
                prompt_summary="error:fridge_recipe",
                input_json={"payload": payload.model_dump(), "fridge_items": fridge_items},
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
