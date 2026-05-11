from collections import defaultdict
from typing import Dict, Iterable, List


NEGATIVE_FEEDBACK_THRESHOLD = 6


def is_negative_feedback(feedback) -> bool:
    symptoms = feedback.extra_symptoms or []
    return (
        (feedback.bloating_level or 0) >= NEGATIVE_FEEDBACK_THRESHOLD
        or (feedback.fatigue_level or 0) >= NEGATIVE_FEEDBACK_THRESHOLD
        or len(symptoms) > 0
    )


def rank_foods_by_feedback(pairs: Iterable[tuple]) -> Dict[str, List[dict]]:
    stats = defaultdict(lambda: {"total": 0, "negative": 0, "calories": 0.0, "protein": 0.0})

    for item, feedback in pairs:
        name = item.food_name
        stats[name]["total"] += 1
        stats[name]["calories"] += float(item.calories or 0)
        stats[name]["protein"] += float(item.protein_g or 0)
        if feedback and is_negative_feedback(feedback):
            stats[name]["negative"] += 1

    black_items = []
    red_items = []
    total_records = sum(value["total"] for value in stats.values()) or 1

    for food_name, value in stats.items():
        support = value["total"] / total_records
        confidence = value["negative"] / value["total"] if value["total"] else 0
        avg_calories = value["calories"] / value["total"]
        avg_protein = value["protein"] / value["total"]

        if value["negative"] > 0 and confidence >= 0.5:
            black_items.append({
                "food_name": food_name,
                "reason": "与腹胀、疲劳或其他餐后不适反馈存在较高关联",
                "support": round(support, 2),
                "confidence": round(confidence, 2),
                "suggestion": "建议减少摄入频率，或尝试替换为更清淡、低敏的食材",
            })
        elif value["negative"] == 0:
            score = min(0.99, 0.45 + avg_protein / 80 + max(0, 450 - avg_calories) / 1000)
            red_items.append({
                "food_name": food_name,
                "reason": "近期负反馈较少，营养结构相对友好",
                "score": round(score, 2),
            })

    return {
        "black_items": sorted(black_items, key=lambda item: item["confidence"], reverse=True)[:5],
        "red_items": sorted(red_items, key=lambda item: item["score"], reverse=True)[:5],
    }
