from __future__ import annotations

from typing import Any, Dict, List, Tuple


def _to_float(x: Any, default: float = 0.0) -> float:
    try:
        if x is None:
            return default
        return float(x)
    except Exception:
        return default


def _clamp01(x: float) -> float:
    if x < 0.0:
        return 0.0
    if x > 1.0:
        return 1.0
    return x


def _norm_contains_any(text: str, needles: List[str]) -> bool:
    t = (text or "").strip()
    if not t:
        return False
    for n in needles:
        s = (n or "").strip()
        if s and s in t:
            return True
    return False


def _parse_positive_int(x: Any) -> int | None:
    if isinstance(x, bool):
        return None
    if isinstance(x, int):
        return x if x > 0 else None
    if isinstance(x, float) and x.is_integer():
        v = int(x)
        return v if v > 0 else None
    if isinstance(x, str) and x.strip().isdigit():
        v = int(x.strip())
        return v if v > 0 else None
    return None


def _apply_calorie_limit(base: float, *, calories: float, max_calories: int | None) -> float:
    if max_calories is None or max_calories <= 0 or calories <= 0:
        return base
    if calories > max_calories:
        excess_ratio = (calories - max_calories) / max_calories
        return base - min(0.45, 0.35 * excess_ratio)
    return base + 0.05


def _apply_ingredient_bias(base: float, *, title: str, preferred: Any, avoid: Any) -> float:
    if isinstance(preferred, list) and _norm_contains_any(title, [str(x) for x in preferred]):
        base += 0.08
    if isinstance(avoid, list) and _norm_contains_any(title, [str(x) for x in avoid]):
        base -= 0.35
    return base


def _apply_goal_adjustment(
    base: float,
    *,
    goal: str,
    calories: float,
    protein: float,
    fat: float,
    carb: float,
) -> float:
    if goal == "lose_fat":
        base += min(0.18, protein / 250.0)
        base -= min(0.22, fat / 200.0)
        if calories > 0:
            base += max(-0.12, min(0.08, (600.0 - calories) / 3000.0))
        return base
    if goal == "gain_muscle":
        base += min(0.28, protein / 180.0)
        if calories > 0:
            base += max(-0.10, min(0.12, (calories - 450.0) / 2500.0))
        base -= min(0.10, fat / 300.0)
        return base
    if goal in ("healthy", "maintain"):
        base += min(0.10, protein / 350.0)
        if calories > 0:
            base -= min(0.10, abs(calories - 550.0) / 3000.0)
        base -= min(0.06, abs(carb - 60.0) / 800.0)
        return base
    return base


def score_recipe(payload: Dict[str, Any], rec: Dict[str, Any]) -> float:
    base = _to_float(rec.get("score"), 0.55)

    nutrition = rec.get("nutrition") if isinstance(rec.get("nutrition"), dict) else {}
    calories = _to_float(nutrition.get("calories"), 0.0)
    protein = _to_float(nutrition.get("protein_g"), 0.0)
    fat = _to_float(nutrition.get("fat_g"), 0.0)
    carb = _to_float(nutrition.get("carbohydrate_g"), 0.0)

    max_calories = _parse_positive_int(payload.get("max_calories"))
    base = _apply_calorie_limit(base, calories=calories, max_calories=max_calories)

    title = str(rec.get("title") or "")
    base = _apply_ingredient_bias(
        base,
        title=title,
        preferred=payload.get("preferred_ingredients") or [],
        avoid=payload.get("avoid_ingredients") or [],
    )

    goal = str(payload.get("goal") or "").lower()
    base = _apply_goal_adjustment(
        base,
        goal=goal,
        calories=calories,
        protein=protein,
        fat=fat,
        carb=carb,
    )

    return _clamp01(base)


def rank_recommendations(payload: Dict[str, Any], recommendations: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    scored: List[Tuple[float, int, Dict[str, Any]]] = []
    for i, r in enumerate(recommendations or []):
        if not isinstance(r, dict):
            continue
        s = score_recipe(payload, r)
        rr = dict(r)
        rr["score"] = s
        scored.append((s, i, rr))
    scored.sort(key=lambda x: (-x[0], x[1]))
    return [x[2] for x in scored]
