import 'package:flutter/foundation.dart';
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

  Future<void> loadBlacklist() async {
    isLoadingBlacklist.value = true;
    errorMessage.value = '';
    try {
      final resp = await _service.getBlacklist();
      if (resp.isSuccess) {
        blacklist.value = resp.data;
        final data = resp.data;
        debugPrint(
          '[HealthReportController] blacklist loaded: blackItems=${data?.blackItems.length ?? 0}, redItems=${data?.redItems.length ?? 0}',
        );
      } else {
        errorMessage.value = resp.message;
        debugPrint(
          '[HealthReportController] blacklist failed: code=${resp.code}, message=${resp.message}',
        );
      }
    } catch (e, st) {
      errorMessage.value = '获取红黑榜失败';
      debugPrint('[HealthReportController] blacklist exception: $e');
      debugPrint('$st');
    } finally {
      isLoadingBlacklist.value = false;
    }
  }

  Future<void> loadWeeklyReport({String? weekStart}) async {
    isLoadingReport.value = true;
    errorMessage.value = '';
    try {
      final resp = await _service.getWeeklyReport(weekStart: weekStart);
      if (resp.isSuccess) {
        weeklyReport.value = resp.data;
        final report = resp.data;
        if (report != null) {
          debugPrint(
            '[HealthReportController] weekly report loaded: weekStart=${report.weekStart}, weekEnd=${report.weekEnd}, avgCalories=${report.avgCalories}, avgProteinG=${report.avgProteinG}, calorieTrend.length=${report.calorieTrend.length}',
          );
        }
      } else {
        errorMessage.value = resp.message;
        debugPrint(
          '[HealthReportController] weekly report failed: code=${resp.code}, message=${resp.message}',
        );
      }
    } catch (e, st) {
      errorMessage.value = '加载健康周报失败';
      debugPrint('[HealthReportController] weekly report exception: $e');
      debugPrint('$st');
    } finally {
      isLoadingReport.value = false;
    }
  }

  Future<void> loadFeedbacks() async {
    try {
      final resp = await _service.getFeedbacks(pageSize: 20);
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        final List<dynamic> listData;
        if (raw is List) {
          listData = raw;
        } else if (raw is Map && raw['items'] is List) {
          listData = raw['items'] as List<dynamic>;
        } else {
          listData = <dynamic>[];
        }

        final list = listData
            .map(
              (e) => HealthFeedbackModel.fromJson(e as Map<String, dynamic>),
            )
            .toList();
        feedbacks.assignAll(list);
        debugPrint(
          '[HealthReportController] feedbacks loaded: count=${feedbacks.length}',
        );
      } else {
        debugPrint(
          '[HealthReportController] feedbacks failed: code=${resp.code}, message=${resp.message}',
        );
      }
    } catch (e, st) {
      debugPrint('[HealthReportController] feedbacks exception: $e');
      debugPrint('$st');
    }
  }

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
        debugPrint(
          '[HealthReportController] submit feedback success: id=${resp.data!.id}',
        );
        await loadFeedbacks();
        await loadBlacklist();
        await loadWeeklyReport();
        return true;
      } else {
        errorMessage.value = resp.message;
        debugPrint(
          '[HealthReportController] submit feedback failed: code=${resp.code}, message=${resp.message}',
        );
        return false;
      }
    } catch (e, st) {
      errorMessage.value = '提交失败，请检查网络';
      debugPrint('[HealthReportController] submit feedback exception: $e');
      debugPrint('$st');
      return false;
    } finally {
      isSubmittingFeedback.value = false;
    }
  }
}
