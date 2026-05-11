from math import sqrt
from typing import Iterable, List, Sequence


TASTE_DIMENSIONS = [
    "high_protein",
    "low_fat",
    "high_carb",
    "vegetable_rich",
    "sweet",
    "spicy",
    "light",
    "meat",
]


FOOD_TAG_RULES = {
    "chicken": ["high_protein", "low_fat", "meat"],
    "egg": ["high_protein"],
    "beef": ["high_protein", "meat"],
    "fish": ["high_protein", "low_fat"],
    "tofu": ["high_protein", "light"],
    "broccoli": ["vegetable_rich", "light"],
    "salad": ["vegetable_rich", "light"],
    "rice": ["high_carb", "light"],
    "noodle": ["high_carb"],
    "cake": ["sweet", "high_carb"],
    "milk tea": ["sweet", "high_carb"],
    "hotpot": ["spicy", "meat"],
    "pepper": ["spicy"],
    "chili": ["spicy"],
    "鸡": ["high_protein", "low_fat", "meat"],
    "蛋": ["high_protein"],
    "牛": ["high_protein", "meat"],
    "鱼": ["high_protein", "low_fat"],
    "豆腐": ["high_protein", "light"],
    "西兰花": ["vegetable_rich", "light"],
    "沙拉": ["vegetable_rich", "light"],
    "米饭": ["high_carb", "light"],
    "面": ["high_carb"],
    "蛋糕": ["sweet", "high_carb"],
    "奶茶": ["sweet", "high_carb"],
    "火锅": ["spicy", "meat"],
    "辣": ["spicy"],
}

TAG_DISPLAY = {
    "high_protein": "高蛋白",
    "low_fat": "低脂",
    "high_carb": "主食党",
    "vegetable_rich": "蔬菜友好",
    "sweet": "甜口",
    "spicy": "重口/辣味",
    "light": "清淡",
    "meat": "肉食偏好",
}


def infer_tags_from_food_name(food_name: str) -> List[str]:
    lowered = food_name.lower()
    tags: List[str] = []
    for keyword, keyword_tags in FOOD_TAG_RULES.items():
        if keyword in lowered:
            tags.extend(keyword_tags)
    return list(dict.fromkeys(tags))


def build_taste_vector(food_names: Iterable[str]) -> tuple[List[float], List[str]]:
    counts = {dimension: 0.0 for dimension in TASTE_DIMENSIONS}
    for food_name in food_names:
        for tag in infer_tags_from_food_name(food_name):
            counts[tag] += 1.0

    max_count = max(counts.values(), default=0.0)
    if max_count <= 0:
        return [0.0 for _ in TASTE_DIMENSIONS], []

    vector = [round(counts[dimension] / max_count, 4) for dimension in TASTE_DIMENSIONS]
    tags = [
        TAG_DISPLAY[dimension]
        for dimension, value in counts.items()
        if value > 0
    ]
    return vector, tags


def cosine_similarity(left: Sequence[float], right: Sequence[float]) -> float:
    length = min(len(left), len(right))
    if length == 0:
        return 0.0
    dot = sum(float(left[i]) * float(right[i]) for i in range(length))
    left_norm = sqrt(sum(float(left[i]) ** 2 for i in range(length)))
    right_norm = sqrt(sum(float(right[i]) ** 2 for i in range(length)))
    if left_norm == 0 or right_norm == 0:
        return 0.0
    return round(dot / (left_norm * right_norm), 4)


def common_tags(left: Sequence[str], right: Sequence[str]) -> List[str]:
    right_set = set(right)
    return [tag for tag in left if tag in right_set]
