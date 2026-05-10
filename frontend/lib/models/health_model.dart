class HealthFeedbackModel {
  final int id;
  final int userId;
  final int foodRecordId;
  final String feedbackTime;
  final int bloatingLevel;
  final int fatigueLevel;
  final String mood;
  final String? digestiveNote;
  final List<String> extraSymptoms;
  final String createdAt;

  HealthFeedbackModel({
    required this.id,
    required this.userId,
    required this.foodRecordId,
    required this.feedbackTime,
    required this.bloatingLevel,
    required this.fatigueLevel,
    required this.mood,
    this.digestiveNote,
    required this.extraSymptoms,
    required this.createdAt,
  });

  factory HealthFeedbackModel.fromJson(Map<String, dynamic> json) {
    return HealthFeedbackModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      foodRecordId: json['food_record_id'] as int? ?? 0,
      feedbackTime: json['feedback_time'] as String? ?? '',
      bloatingLevel: json['bloating_level'] as int? ?? 0,
      fatigueLevel: json['fatigue_level'] as int? ?? 0,
      mood: json['mood'] as String? ?? 'normal',
      digestiveNote: json['digestive_note'] as String?,
      extraSymptoms: (json['extra_symptoms'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class BlacklistItemModel {
  final String foodName;
  final String reason;
  final double support;
  final double confidence;
  final String? suggestion;

  BlacklistItemModel({
    required this.foodName,
    required this.reason,
    required this.support,
    required this.confidence,
    this.suggestion,
  });

  factory BlacklistItemModel.fromJson(Map<String, dynamic> json) {
    return BlacklistItemModel(
      foodName: json['food_name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      support: (json['support'] as num? ?? 0).toDouble(),
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      suggestion: json['suggestion'] as String?,
    );
  }
}

class RedlistItemModel {
  final String foodName;
  final String reason;
  final double score;

  RedlistItemModel({
    required this.foodName,
    required this.reason,
    required this.score,
  });

  factory RedlistItemModel.fromJson(Map<String, dynamic> json) {
    return RedlistItemModel(
      foodName: json['food_name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      score: (json['score'] as num? ?? 0).toDouble(),
    );
  }
}

class BlacklistModel {
  final List<BlacklistItemModel> blackItems;
  final List<RedlistItemModel> redItems;
  final String generatedAt;

  BlacklistModel({
    required this.blackItems,
    required this.redItems,
    required this.generatedAt,
  });

  factory BlacklistModel.fromJson(Map<String, dynamic> json) {
    return BlacklistModel(
      blackItems: (json['black_items'] as List<dynamic>? ?? [])
          .map((e) => BlacklistItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      redItems: (json['red_items'] as List<dynamic>? ?? [])
          .map((e) => RedlistItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }
}

class CalorieTrendPoint {
  final String date;
  final double calories;

  CalorieTrendPoint({required this.date, required this.calories});

  factory CalorieTrendPoint.fromJson(Map<String, dynamic> json) {
    return CalorieTrendPoint(
      date: json['date'] as String? ?? '',
      calories: (json['calories'] as num? ?? 0).toDouble(),
    );
  }
}

class WeeklyReportModel {
  final String weekStart;
  final String weekEnd;
  final double avgCalories;
  final double avgProteinG;
  final List<CalorieTrendPoint> calorieTrend;
  final List<String> warnings;
  final List<String> suggestions;

  WeeklyReportModel({
    required this.weekStart,
    required this.weekEnd,
    required this.avgCalories,
    required this.avgProteinG,
    required this.calorieTrend,
    required this.warnings,
    required this.suggestions,
  });

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReportModel(
      weekStart: json['week_start'] as String? ?? '',
      weekEnd: json['week_end'] as String? ?? '',
      avgCalories: (json['avg_calories'] as num? ?? 0).toDouble(),
      avgProteinG: (json['avg_protein_g'] as num? ?? 0).toDouble(),
      calorieTrend: (json['calorie_trend'] as List<dynamic>? ?? [])
          .map((e) => CalorieTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      suggestions: (json['suggestions'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
