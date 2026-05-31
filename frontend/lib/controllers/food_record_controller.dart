import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'home_controller.dart';
import '../models/food_record_model.dart';
import '../services/api/food_record_service.dart';

class FoodRecordController extends GetxController {
  final FoodRecordService _service = FoodRecordService.instance;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<FoodRecordModel> records = <FoodRecordModel>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString errorDetail = ''.obs;

  // 当前筛选日期（格式 YYYY-MM-DD）
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadRecords();
  }

  /// 加载指定日期的饮食记录
  Future<void> loadRecords({DateTime? date}) async {
    isLoading.value = true;
    errorMessage.value = '';
    errorDetail.value = '';
    try {
      final d = date ?? selectedDate.value;
      final dayStart = DateTime(d.year, d.month, d.day, 0, 0, 0);
      final dayEnd = DateTime(d.year, d.month, d.day, 23, 59, 59);
      final resp = await _service.getRecords(
        startDate: dayStart.toIso8601String(),
        endDate: dayEnd.toIso8601String(),
        pageSize: 50,
      );
      if (resp.isSuccess && resp.data != null) {
        records.assignAll(resp.data!);
      } else {
        errorMessage.value = '暂时无法加载饮食记录，请检查后端服务或稍后重试。';
        errorDetail.value = resp.message;
        debugPrint('==== 饮食记录加载失败 ====');
        debugPrint('错误信息: ${resp.message}');
      }
    } catch (e, stackTrace) {
      // 🚨 【核心修复点】: 打印出真正的错误堆栈，不要吞掉错误！
      debugPrint('==== 饮食记录加载崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      
      // 页面只显示短提示，完整异常保留在详情和控制台日志里。
      errorMessage.value = '暂时无法加载饮食记录，请检查后端服务或稍后重试。';
      errorDetail.value = '$e\n$stackTrace';
    } finally {
      isLoading.value = false;
    }
  }

  /// 切换日期
  Future<void> changeDate(DateTime date) async {
    selectedDate.value = date;
    await loadRecords(date: date);
  }

  /// 新增饮食记录，返回是否成功
  Future<bool> createRecord({
    required String mealType,
    required DateTime recordTime,
    required String sourceType,
    String? description,
    required List<FoodItemModel> items,
  }) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final timeStr = recordTime.toIso8601String();
      final resp = await _service.createRecord(
        mealType: mealType,
        recordTime: timeStr,
        sourceType: sourceType,
        description: description,
        items: items,
      );
      if (resp.isSuccess && resp.data != null) {
        await loadRecords();
        await _refreshHomeDashboardIfNeeded();
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e, stackTrace) {
      // 🚨 【核心修复点】
      debugPrint('==== 新增饮食记录崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      
      errorMessage.value = '提交崩溃: $e';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 删除饮食记录，返回是否成功
  Future<bool> deleteRecord(int recordId) async {
    errorMessage.value = '';
    try {
      final resp = await _service.deleteRecord(recordId);
      if (resp.isSuccess) {
        records.removeWhere((r) => r.id == recordId);
        await _refreshHomeDashboardIfNeeded();
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e, stackTrace) {
      // 🚨 【核心修复点】
      debugPrint('==== 删除饮食记录崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      
      errorMessage.value = '删除崩溃: $e';
      return false;
    }
  }

  /// 当日总热量
  double get todayTotalCalories =>
      records.fold(0.0, (sum, r) => sum + r.totalCalories);

  /// 当日总蛋白质
  double get todayTotalProtein =>
      records.fold(0.0, (sum, r) => sum + r.totalProteinG);

  /// 当日总脂肪
  double get todayTotalFat =>
      records.fold(0.0, (sum, r) => sum + r.totalFatG);

  /// 当日总碳水
  double get todayTotalCarbohydrate =>
      records.fold(0.0, (sum, r) => sum + r.totalCarbohydrateG);

  Future<bool> updateRecord({
    required int recordId,
    required String mealType,
    required DateTime recordTime,
    required String sourceType,
    String? description,
    required List<FoodItemModel> items,
  }) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final resp = await _service.updateRecord(
        recordId: recordId,
        mealType: mealType,
        recordTime: recordTime.toIso8601String(),
        sourceType: sourceType,
        description: description,
        items: items,
      );
      if (resp.isSuccess && resp.data != null) {
        await loadRecords();
        await _refreshHomeDashboardIfNeeded();
        return true;
      }
      errorMessage.value = resp.message;
      return false;
    } catch (e, stackTrace) {
      debugPrint('==== 修改饮食记录崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      errorMessage.value = '修改崩溃: $e';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _refreshHomeDashboardIfNeeded() async {
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().loadDashboard();
    }
  }
}
