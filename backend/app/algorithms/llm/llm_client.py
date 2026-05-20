from __future__ import annotations

import base64
import json
import re
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import httpx

from app.algorithms.llm.prompt_templates import (
    build_food_recognition_prompt,
    build_fridge_recognition_prompt,
    build_fridge_recipe_prompt,
    build_recommendation_prompt,
)

# ARK（豆包）Responses API 地址
_ARK_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
_ARK_DEFAULT_MODEL = "doubao-seed-2-0-pro-260215"


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
        self.base_url = (base_url or "").rstrip("/")
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

    # ------------------------------------------------------------------
    # 多模态识别：从视频帧 + 语音文本识别食物（饮食记录用）
    # ------------------------------------------------------------------
    def recognize_food_from_frames(
        self,
        frames_b64: List[str],
        audio_text: str = "",
    ) -> LLMResult:
        """
        输入：base64 编码的视频关键帧列表 + 语音转文字文本
        输出：符合 RecordStandardizer.ai_result_to_food_record 格式的 JSON
        """
        prompt = build_food_recognition_prompt(audio_text)

        if self.provider == "mock":
            return LLMResult(
                prompt_summary="mock:food_recognition",
                output_json={
                    "foods": [
                        {
                            "name": "白米饭",
                            "weight_g": 200,
                            "calories": 260,
                            "protein_g": 5.0,
                            "fat_g": 0.5,
                            "carbohydrate_g": 57.0,
                            "confidence": 0.92,
                        },
                        {
                            "name": "红烧肉",
                            "weight_g": 100,
                            "calories": 380,
                            "protein_g": 18.0,
                            "fat_g": 28.0,
                            "carbohydrate_g": 12.0,
                            "confidence": 0.87,
                        },
                    ]
                },
            )

        if self.provider == "ark":
            return self._ark_vision_call(
                prompt=prompt,
                frames_b64=frames_b64,
                summary_key="ark:food_recognition",
            )

        return self._not_implemented()

    # ------------------------------------------------------------------
    # 多模态识别：从视频帧 + 语音文本识别冰箱食材
    # ------------------------------------------------------------------
    def recognize_fridge_from_frames(
        self,
        frames_b64: List[str],
        audio_text: str = "",
    ) -> LLMResult:
        """
        输入：base64 编码的视频关键帧列表 + 语音转文字文本
        输出：冰箱食材列表 JSON
        """
        prompt = build_fridge_recognition_prompt(audio_text)

        if self.provider == "mock":
            return LLMResult(
                prompt_summary="mock:fridge_recognition",
                output_json={
                    "items": [
                        {"name": "牛奶", "quantity": 1, "unit": "盒", "category": "乳制品", "confidence": 0.95},
                        {"name": "鸡蛋", "quantity": 6, "unit": "个", "category": "蛋类", "confidence": 0.93},
                        {"name": "胡萝卜", "quantity": 2, "unit": "根", "category": "蔬菜", "confidence": 0.88},
                    ]
                },
            )

        if self.provider == "ark":
            return self._ark_vision_call(
                prompt=prompt,
                frames_b64=frames_b64,
                summary_key="ark:fridge_recognition",
            )

        return self._not_implemented()

    # ------------------------------------------------------------------
    # 推荐菜谱
    # ------------------------------------------------------------------
    def generate_recommendations(self, payload: Dict[str, Any]) -> LLMResult:
        prompt = build_recommendation_prompt(payload)
        if self.provider == "mock":
            out = {
                "recommendations": [
                    {
                        "title": "西兰花鸡胸肉晚餐",
                        "reason": "符合减脂和高蛋白目标",
                        "nutrition": {"calories": 520, "protein_g": 45, "fat_g": 10, "carbohydrate_g": 55},
                        "score": 0.78,
                    },
                    {
                        "title": "炸鸡排盖饭",
                        "reason": "口感满足，但油脂和热量较高",
                        "nutrition": {"calories": 860, "protein_g": 32, "fat_g": 42, "carbohydrate_g": 85},
                        "score": 0.72,
                    },
                    {
                        "title": "番茄牛肉饭",
                        "reason": "蛋白质不错，注意米饭分量",
                        "nutrition": {"calories": 640, "protein_g": 38, "fat_g": 18, "carbohydrate_g": 70},
                        "score": 0.74,
                    },
                ]
            }
            return LLMResult(prompt_summary="mock:recommendations", output_json=out)

        if self.provider == "ark":
            return self._ark_text_call(prompt=prompt, summary_key="ark:recommendations")

        return self._not_implemented()

    # ------------------------------------------------------------------
    # 冰箱菜谱生成
    # ------------------------------------------------------------------
    def generate_fridge_recipe(
        self, payload: Dict[str, Any], fridge_items: List[Dict[str, Any]]
    ) -> LLMResult:
        prompt = build_fridge_recipe_prompt(payload, fridge_items)
        if self.provider == "mock":
            usable = [x for x in fridge_items if x.get("name") and x.get("name") not in set(payload.get("avoid_ingredients") or [])]
            if not usable:
                raise LLMError("冰箱没有可用食材，请先添加食材")
            chosen = usable[:4]
            title = f"{chosen[0].get('name')}高蛋白菜谱"
            out = {
                "recipe_id": 0,
                "title": title,
                "description": "优先使用临期食材，适合当前目标。",
                "ingredients": [{"name": x.get("name"), "amount": f"{x.get('quantity') or 1}{x.get('unit') or ''}"} for x in chosen],
                "steps": ["准备食材并清洗处理。", "按顺序下锅翻炒或煮熟。", "调味后装盘即可。"],
                "nutrition": {"calories": payload.get("max_calories") or 520, "protein_g": 42, "fat_g": 12, "carbohydrate_g": 58},
                "score": 0.91,
            }
            return LLMResult(prompt_summary="mock:fridge_recipe", output_json=out)

        if self.provider == "ark":
            return self._ark_text_call(prompt=prompt, summary_key="ark:fridge_recipe")

        return self._not_implemented()

    # ------------------------------------------------------------------
    # 内部：ARK Responses API 多模态视觉调用
    # 使用 input_image / input_text 格式（豆包 Responses API 规范）
    # ------------------------------------------------------------------
    def _ark_vision_call(
        self,
        *,
        prompt: str,
        frames_b64: List[str],
        summary_key: str,
    ) -> LLMResult:
        if not self.api_key:
            raise LLMError("LLM_API_KEY 未配置，请在 .env 中填写 ARK API Key")

        base_url = self.base_url or _ARK_BASE_URL
        url = f"{base_url}/responses"
        model = self.model if self.model and self.model != "mock" else _ARK_DEFAULT_MODEL

        content: List[Dict[str, Any]] = []
        for b64 in frames_b64[:6]:  # 最多 6 帧，避免超 token
            content.append({
                "type": "input_image",
                "image_url": f"data:image/jpeg;base64,{b64}",
            })
        content.append({"type": "input_text", "text": prompt})

        payload = {
            "model": model,
            "input": [{"role": "user", "content": content}],
        }

        raw = self._http_post_json(url, payload)
        text = self._extract_text_from_response(raw)
        return LLMResult(
            prompt_summary=summary_key,
            output_json=self._extract_json(text),
        )

    # ------------------------------------------------------------------
    # 内部：ARK Responses API 纯文字调用
    # ------------------------------------------------------------------
    def _ark_text_call(self, *, prompt: str, summary_key: str) -> LLMResult:
        if not self.api_key:
            raise LLMError("LLM_API_KEY 未配置，请在 .env 中填写 ARK API Key")

        base_url = self.base_url or _ARK_BASE_URL
        url = f"{base_url}/responses"
        model = self.model if self.model and self.model != "mock" else _ARK_DEFAULT_MODEL

        payload = {
            "model": model,
            "input": [{"role": "user", "content": [{"type": "input_text", "text": prompt}]}],
        }

        raw = self._http_post_json(url, payload)
        text = self._extract_text_from_response(raw)
        return LLMResult(
            prompt_summary=summary_key,
            output_json=self._extract_json(text),
        )

    # ------------------------------------------------------------------
    # 工具方法
    # ------------------------------------------------------------------
    def _not_implemented(self) -> LLMResult:
        if not self.base_url:
            raise LLMError("LLM_BASE_URL 未配置")
        raise LLMError(f"LLM provider '{self.provider}' 未实现")

    def _http_post_json(self, url: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        headers = {"Content-Type": "application/json"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        # connect/write 用 15s 固定值，read 用配置的 timeout_seconds（LLM 推理耗时长）
        timeout = httpx.Timeout(
            connect=15.0,
            write=30.0,
            read=float(self.timeout_seconds),
            pool=15.0,
        )
        with httpx.Client(timeout=timeout) as client:
            r = client.post(url, json=payload, headers=headers)
            r.raise_for_status()
            return r.json()

    @staticmethod
    def _extract_text_from_response(raw: Dict[str, Any]) -> str:
        """从 ARK Responses API 响应中提取文本内容。
        output 数组可能同时包含 reasoning（思维链）和 message（回答），只取 message 类型。
        """
        # 遍历 output，只处理 type==message 的项（跳过 reasoning 等）
        for item in raw.get("output", []):
            if item.get("type") != "message":
                continue
            for c in item.get("content", []):
                if c.get("type") == "output_text" and c.get("text"):
                    return c["text"]
        raise LLMError(f"无法从响应中提取文本，原始响应: {str(raw)[:300]}")

    @staticmethod
    def _extract_json(text: str) -> Dict[str, Any]:
        """从模型返回文本中提取 JSON 块，兼容 ```json ... ``` 格式。"""
        # 尝试提取 markdown 代码块
        match = re.search(r"```(?:json)?\s*(\{[\s\S]*?\})\s*```", text)
        if match:
            text = match.group(1)
        else:
            # 尝试找最外层 { }
            start = text.find("{")
            end = text.rfind("}")
            if start != -1 and end != -1:
                text = text[start : end + 1]
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            raise LLMError(f"模型返回的 JSON 解析失败: {exc}\n原始内容: {text[:300]}") from exc

