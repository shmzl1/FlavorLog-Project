from typing import Any, Dict, List


def build_recommendation_prompt(payload: Dict[str, Any]) -> str:
    goal = payload.get("goal")
    meal_type = payload.get("meal_type")
    max_calories = payload.get("max_calories")
    preferred = payload.get("preferred_ingredients") or []
    avoid = payload.get("avoid_ingredients") or []

    lines = [
        "你是营养师，请给出 1-3 个食谱推荐。",
        f"目标: {goal}",
        f"餐别: {meal_type}",
        f"热量上限: {max_calories}" if max_calories is not None else "热量上限: 无",
        f"偏好食材: {', '.join(preferred) if preferred else '无'}",
        f"忌口食材: {', '.join(avoid) if avoid else '无'}",
        "输出 JSON：recommendations 数组，每项包含 title, reason, nutrition, score。",
    ]
    return "\n".join(lines)


def build_fridge_recipe_prompt(payload: Dict[str, Any], fridge_items: List[Dict[str, Any]]) -> str:
    target = payload.get("target")
    max_calories = payload.get("max_calories")
    preferred_cuisine = payload.get("preferred_cuisine")
    avoid = payload.get("avoid_ingredients") or []
    use_expiring_first = payload.get("use_expiring_first")

    lines = [
        "你是家用厨师与营养师，请基于冰箱食材生成 1 个可执行菜谱。",
        f"目标: {target}",
        f"菜系偏好: {preferred_cuisine or '无'}",
        f"热量上限: {max_calories}" if max_calories is not None else "热量上限: 无",
        f"忌口食材: {', '.join(avoid) if avoid else '无'}",
        f"临期优先: {bool(use_expiring_first)}",
        f"冰箱食材数量: {len(fridge_items)}",
        "输出 JSON：recipe_id 可为空；包含 title, description, ingredients[], steps[], nutrition{}, score。",
    ]
    return "\n".join(lines)
