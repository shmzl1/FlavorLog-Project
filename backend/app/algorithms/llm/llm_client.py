from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import httpx

from app.algorithms.llm.prompt_templates import (
    build_fridge_recipe_prompt,
    build_recommendation_prompt,
)


@dataclass(frozen=True)
class LLMResult:
    prompt_summary: str
    output_json: Dict[str, Any]


class LLMError(RuntimeError):
    pass


class LLMClient:
    def __init__(
        self,
        *,
        provider: str,
        api_key: str = "",
        base_url: str = "",
        model: str = "mock",
        timeout_seconds: int = 60,
    ) -> None:
        self.provider = (provider or "mock").lower()
        self.api_key = api_key or ""
        self.base_url = base_url or ""
        self.model = model or "mock"
        self.timeout_seconds = timeout_seconds

    @classmethod
    def from_settings(cls, settings: Any) -> "LLMClient":
        timeout = getattr(settings, "LLM_TIMEOUT_SECONDS", 60)
        return cls(
            provider=getattr(settings, "LLM_PROVIDER", "mock"),
            api_key=getattr(settings, "LLM_API_KEY", ""),
            base_url=getattr(settings, "LLM_BASE_URL", ""),
            model=getattr(settings, "LLM_MODEL", "mock"),
            timeout_seconds=int(timeout) if timeout else 60,
        )

    def generate_recommendations(self, payload: Dict[str, Any]) -> LLMResult:
        prompt = build_recommendation_prompt(payload)
        if self.provider == "mock":
            out = {
                "recommendations": [
                    {
                        "title": "西兰花鸡胸肉晚餐",
                        "reason": "符合减脂和高蛋白目标",
                        "nutrition": {
                            "calories": 520,
                            "protein_g": 45,
                            "fat_g": 10,
                            "carbohydrate_g": 55,
                        },
                        "score": 0.78,
                    },
                    {
                        "title": "炸鸡排盖饭",
                        "reason": "口感满足，但油脂和热量较高",
                        "nutrition": {
                            "calories": 860,
                            "protein_g": 32,
                            "fat_g": 42,
                            "carbohydrate_g": 85,
                        },
                        "score": 0.72,
                    },
                    {
                        "title": "番茄牛肉饭",
                        "reason": "蛋白质不错，注意米饭分量",
                        "nutrition": {
                            "calories": 640,
                            "protein_g": 38,
                            "fat_g": 18,
                            "carbohydrate_g": 70,
                        },
                        "score": 0.74,
                    }
                ]
            }
            return LLMResult(prompt_summary="mock:recommendations", output_json=out)
        return self._not_implemented(prompt)

    def generate_fridge_recipe(
        self, payload: Dict[str, Any], fridge_items: List[Dict[str, Any]]
    ) -> LLMResult:
        prompt = build_fridge_recipe_prompt(payload, fridge_items)
        if self.provider == "mock":
            usable = [
                x for x in fridge_items if x.get("name") and x.get("name") not in set(payload.get("avoid_ingredients") or [])
            ]
            if not usable:
                raise LLMError("冰箱没有可用食材，请先添加食材")

            chosen = usable[:4]
            title = f"{chosen[0].get('name')}高蛋白菜谱"
            out = {
                "recipe_id": 0,
                "title": title,
                "description": "优先使用临期食材，适合当前目标。",
                "ingredients": [
                    {"name": x.get("name"), "amount": f"{x.get('quantity') or 1}{x.get('unit') or ''}"}
                    for x in chosen
                ],
                "steps": [
                    "准备食材并清洗处理。",
                    "按顺序下锅翻炒或煮熟。",
                    "调味后装盘即可。",
                ],
                "nutrition": {
                    "calories": payload.get("max_calories") or 520,
                    "protein_g": 42,
                    "fat_g": 12,
                    "carbohydrate_g": 58,
                },
                "score": 0.91,
            }
            return LLMResult(prompt_summary="mock:fridge_recipe", output_json=out)
        return self._not_implemented(prompt)

    def _not_implemented(self, prompt: str) -> LLMResult:
        if not self.base_url:
            raise LLMError("LLM_BASE_URL 未配置")
        raise LLMError(f"LLM provider '{self.provider}' 未实现")

    def _http_post_json(self, url: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        headers = {}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        with httpx.Client(timeout=self.timeout_seconds) as client:
            r = client.post(url, json=payload, headers=headers)
            r.raise_for_status()
            return r.json()
