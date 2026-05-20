from typing import Any, Dict, List


def build_food_recognition_prompt(audio_text: str = "") -> str:
    """多模态饮食记录识别 prompt。"""
    audio_hint = f"\n语音补充信息：\u300c{audio_text}\u300d" if audio_text.strip() else ""
    return (
        "你是专业营养师，请仔细观察图片中的食物，识别所有可见的食物种类及分量。"
        f"{audio_hint}\n"
        "请以 JSON 格式输出，结构如下（每种食物一个对象）：\n"
        "{\n"
        '  "foods": [\n'
        "    {\n"
        '      "name": "食物名称（中文）",\n'
        '      "weight_g": 估计克重（数字）,\n'
        '      "calories": 热量kcal（数字）,\n'
        '      "protein_g": 蛋白质g（数字）,\n'
        '      "fat_g": 脂肪g（数字）,\n'
        '      "carbohydrate_g": 碳水g（数字）,\n'
        '      "confidence": 识别置信度0~1（数字）\n'
        "    }\n"
        "  ]\n"
        "}\n"
        "注意：只输出 JSON，不要输出其他文字。"
    )


def build_fridge_recognition_prompt(audio_text: str = "") -> str:
    """多模态冰箱食材识别 prompt。"""
    audio_hint = f"\n语音补充信息：\u300c{audio_text}\u300d" if audio_text.strip() else ""
    return (
        "你是食材管理助手，请仔细观察图片中冰箱/食物货架上的所有食材，识别品类、数量和单位。"
        f"{audio_hint}\n"
        "请以 JSON 格式输出，结构如下：\n"
        "{\n"
        '  "items": [\n'
        "    {\n"
        '      "name": "食材名称（中文）",\n'
        '      "quantity": 数量（数字）,\n'
        '      "unit": "单位（个/袋/盒/克/升等）",\n'
        '      "category": "分类（蔬菜/水果/肉类/乳制品/饮料/调味品/其他）",\n'
        '      "confidence": 识别置信度0~1（数字）\n'
        "    }\n"
        "  ]\n"
        "}\n"
        "注意：只输出 JSON，不要输出其他文字。"
    )


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
