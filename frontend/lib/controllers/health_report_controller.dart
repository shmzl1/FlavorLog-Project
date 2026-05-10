import 'package:get/get.dart';

import '../models/health_model.dart';
import '../services/api/health_service.dart';

class HealthReportController extends GetxController {
  final HealthService _service = HealthService.instance;

  final RxBool isLoadingBlacklist = false.obs;
  final RxBool isLoadingReport = false.obs;
  final RxBool isSubmittingFeedback = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<BlacklistModel?> blacklist = Rx<BlacklistModel?>(null);
  final Rx<WeeklyReportModel?> weeklyReport = Rx<WeeklyReportModel?>(null);
  final RxList<HealthFeedbackModel> feedbacks = <HealthFeedbackModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadBlacklist();
    loadWeeklyReport();
    loadFeedbacks();
  }

  /// 获取红黑榜
  Future<void> loadBlacklist() async {
    isLoadingBlacklist.value = true;
    errorMessage.value = '';
    try {
      final resp = await _service.getBlacklist();
      if (resp.isSuccess) {
        blacklist.value = resp.data;
      } else {
        errorMessage.value = resp.message;
      }
    } catch (e) {
      errorMessage.value = '获取红黑榜失败';
    } finally {
      isLoadingBlacklist.value = false;
    }
  }

  /// 获取健康周报
  Future<void> loadWeeklyReport({String? weekStart}) async {
    isLoadingReport.value = true;
    try {
      final resp = await _service.getWeeklyReport(weekStart: weekStart);
      if (resp.isSuccess) {
        weeklyReport.value = resp.data;
      }
    } catch (_) {
      // 静默，周报不影响主页面
    } finally {
      isLoadingReport.value = false;
    }
  }

  /// 获取健康反馈列表
  Future<void> loadFeedbacks() async {
    try {
      final resp = await _service.getFeedbacks(pageSize: 20);
      if (resp.isSuccess && resp.data != null) {
        final list = (resp.data!['items'] as List<dynamic>? ?? [])
            .map((e) =>
                HealthFeedbackModel.fromJson(e as Map<String, dynamic>))
            .toList();
        feedbacks.assignAll(list);
      }
    } catch (_) {}
  }

  /// 提交餐后反馈
  Future<bool> submitFeedback({
    required int foodRecordId,
    required int bloatingLevel,
    required int fatigueLevel,
    required String mood,
    String? digestiveNote,
    List<String>? extraSymptoms,
  }) async {
    isSubmittingFeedback.value = true;
    errorMessage.value = '';
    try {
      final feedbackTime = DateTime.now().toIso8601String();
      final resp = await _service.createFeedback(
        foodRecordId: foodRecordId,
        feedbackTime: feedbackTime,
        bloatingLevel: bloatingLevel,
        fatigueLevel: fatigueLevel,
        mood: mood,
        digestiveNote: digestiveNote,
        extraSymptoms: extraSymptoms,
      );
      if (resp.isSuccess && resp.data != null) {
        feedbacks.insert(0, resp.data!);
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e) {
      errorMessage.value = '提交失败，请检查网络';
      return false;
    } finally {
      isSubmittingFeedback.value = false;
    }
  }
}