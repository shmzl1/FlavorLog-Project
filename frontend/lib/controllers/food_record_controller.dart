import 'package:get/get.dart';

import '../models/food_record_model.dart';
import '../services/api/food_record_service.dart';

class FoodRecordController extends GetxController {
  final FoodRecordService _service = FoodRecordService.instance;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<FoodRecordModel> records = <FoodRecordModel>[].obs;
  final RxString errorMessage = ''.obs;

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
    try {
      final d = date ?? selectedDate.value;
      final dateStr =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final resp = await _service.getRecords(
        startDate: dateStr,
        endDate: dateStr,
        pageSize: 50,
      );
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data!;
        final items = (raw['items'] as List<dynamic>? ?? [])
            .map((e) => FoodRecordModel.fromJson(e as Map<String, dynamic>))
            .toList();
        records.assignAll(items);
      } else {
        errorMessage.value = resp.message;
      }
    } catch (e) {
      errorMessage.value = '网络请求失败，请检查连接';
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
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e) {
      errorMessage.value = '提交失败，请检查网络';
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
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e) {
      errorMessage.value = '删除失败，请检查网络';
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
}