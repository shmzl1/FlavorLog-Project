import '../../models/health_model.dart';
import '../../models/api_response.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final ApiClient _client = ApiClient.instance;

  /// 新增餐后反馈 POST /health/feedbacks
  Future<ApiResponse<HealthFeedbackModel>> createFeedback({
    required int foodRecordId,
    required String feedbackTime,
    required int bloatingLevel,
    required int fatigueLevel,
    required String mood,
    String? digestiveNote,
    List<String>? extraSymptoms,
  }) async {
    final body = {
      'food_record_id': foodRecordId,
      'feedback_time': feedbackTime,
      'bloating_level': bloatingLevel,
      'fatigue_level': fatigueLevel,
      'mood': mood,
      if (digestiveNote != null) 'digestive_note': digestiveNote,
      if (extraSymptoms != null) 'extra_symptoms': extraSymptoms,
    };
    final resp =
        await _client.post(ApiEndpoints.healthFeedbacks, data: body);
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => HealthFeedbackModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// 获取健康反馈列表 GET /health/feedbacks
  Future<ApiResponse<Map<String, dynamic>>> getFeedbacks({
    int page = 1,
    int pageSize = 10,
    String? startDate,
    String? endDate,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };
    final resp = await _client.get(
      ApiEndpoints.healthFeedbacks,
      queryParameters: params,
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }

  /// 获取食物红黑榜 GET /health/blacklist
  Future<ApiResponse<BlacklistModel>> getBlacklist() async {
    final resp = await _client.get(ApiEndpoints.healthBlacklist);
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => BlacklistModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// 获取健康周报 GET /health/weekly-report
  Future<ApiResponse<WeeklyReportModel>> getWeeklyReport({
    String? weekStart,
  }) async {
    final params = <String, dynamic>{
      if (weekStart != null) 'week_start': weekStart,
    };
    final resp = await _client.get(
      '/health/weekly-report',
      queryParameters: params.isEmpty ? null : params,
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => WeeklyReportModel.fromJson(raw as Map<String, dynamic>),
    );
  }
}
