class FoodRecordModel {
  final int id;
  final String mealType;
  final String recordTime;
  final String sourceType;
  final String? description;
  final double totalCalories;

  FoodRecordModel({
    required this.id,
    required this.mealType,
    required this.recordTime,
    required this.sourceType,
    this.description,
    required this.totalCalories,
  });

  factory FoodRecordModel.fromJson(Map<String, dynamic> json) {
    return FoodRecordModel(
      id: json['id'] as int,
      mealType: json['meal_type'] as String? ?? '',
      recordTime: json['record_time'] as String? ?? '',
      sourceType: json['source_type'] as String? ?? '',
      description: json['description'] as String?,
      totalCalories: (json['total_calories'] as num? ?? 0).toDouble(),
    );
  }
}