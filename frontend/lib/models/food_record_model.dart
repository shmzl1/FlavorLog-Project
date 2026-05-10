class FoodItemModel {
  final int? id;
  final String foodName;
  final double weightG;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbohydrateG;
  final double confidence;

  FoodItemModel({
    this.id,
    required this.foodName,
    required this.weightG,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbohydrateG,
    this.confidence = 1.0,
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      id: json['id'] as int?,
      foodName: json['food_name'] as String? ?? '',
      weightG: (json['weight_g'] as num? ?? 0).toDouble(),
      calories: (json['calories'] as num? ?? 0).toDouble(),
      proteinG: (json['protein_g'] as num? ?? 0).toDouble(),
      fatG: (json['fat_g'] as num? ?? 0).toDouble(),
      carbohydrateG: (json['carbohydrate_g'] as num? ?? 0).toDouble(),
      confidence: (json['confidence'] as num? ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'weight_g': weightG,
      'calories': calories,
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbohydrate_g': carbohydrateG,
      'confidence': confidence,
    };
  }
}

class FoodRecordModel {
  final int id;
  final int userId;
  final String mealType;
  final String recordTime;
  final String sourceType;
  final String? description;
  final double totalCalories;
  final double totalProteinG;
  final double totalFatG;
  final double totalCarbohydrateG;
  final List<FoodItemModel> items;
  final String createdAt;

  FoodRecordModel({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.recordTime,
    required this.sourceType,
    this.description,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalFatG,
    required this.totalCarbohydrateG,
    required this.items,
    required this.createdAt,
  });

  factory FoodRecordModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return FoodRecordModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      mealType: json['meal_type'] as String? ?? '',
      recordTime: json['record_time'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? '',
      description: json['description'] as String?,
      totalCalories: (json['total_calories'] as num? ?? 0).toDouble(),
      totalProteinG: (json['total_protein_g'] as num? ?? 0).toDouble(),
      totalFatG: (json['total_fat_g'] as num? ?? 0).toDouble(),
      totalCarbohydrateG:
          (json['total_carbohydrate_g'] as num? ?? 0).toDouble(),
      items: rawItems
          .map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class PhotoRecognitionDraft {
  final String draftId;
  final String sourceType;
  final List<FoodItemModel> items;
  final bool needUserConfirm;

  PhotoRecognitionDraft({
    required this.draftId,
    required this.sourceType,
    required this.items,
    required this.needUserConfirm,
  });

  factory PhotoRecognitionDraft.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PhotoRecognitionDraft(
      draftId: json['draft_id'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? 'photo',
      items: rawItems
          .map((e) => FoodItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      needUserConfirm: json['need_user_confirm'] as bool? ?? true,
    );
  }
}