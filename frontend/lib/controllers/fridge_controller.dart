import 'package:get/get.dart';

import '../models/fridge_item_model.dart';
import '../services/api/fridge_service.dart';

class FridgeController extends GetxController {
  final FridgeService _service = FridgeService.instance;

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<FridgeItemModel> items = <FridgeItemModel>[].obs;
  final RxString errorMessage = ''.obs;

  // 食谱任务
  final RxString recipeTaskId = ''.obs;
  final RxString recipeTaskStatus = ''.obs;
  final Rx<Map<String, dynamic>?> recipeResult =
      Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  /// 加载冰箱食材列表
  Future<void> loadItems() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await _service.getItems(pageSize: 100);
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data!;
        final list = (raw['items'] as List<dynamic>? ?? [])
            .map((e) => FridgeItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        items.assignAll(list);
      } else {
        errorMessage.value = resp.message;
      }
    } catch (e) {
      errorMessage.value = '网络请求失败，请检查连接';
    } finally {
      isLoading.value = false;
    }
  }

  /// 新增食材，返回是否成功
  Future<bool> createItem({
    required String name,
    String? category,
    required double quantity,
    String? unit,
    double? weightG,
    String? expireDate,
    String? storageLocation,
    String? remark,
  }) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    try {
      final resp = await _service.createItem(
        name: name,
        category: category,
        quantity: quantity,
        unit: unit,
        weightG: weightG,
        expireDate: expireDate,
        storageLocation: storageLocation,
        remark: remark,
      );
      if (resp.isSuccess && resp.data != null) {
        items.insert(0, resp.data!);
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

  /// 删除食材
  Future<bool> deleteItem(int itemId) async {
    errorMessage.value = '';
    try {
      final resp = await _service.deleteItem(itemId);
      if (resp.isSuccess) {
        items.removeWhere((i) => i.id == itemId);
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

  /// 提交食谱生成任务
  Future<bool> submitRecipeTask({
    String? target,
    List<String>? avoidIngredients,
    String? preferredCuisine,
    int? maxCalories,
  }) async {
    isSubmitting.value = true;
    errorMessage.value = '';
    recipeTaskId.value = '';
    recipeTaskStatus.value = '';
    recipeResult.value = null;
    try {
      final resp = await _service.createRecipeTask(
        target: target,
        avoidIngredients: avoidIngredients,
        preferredCuisine: preferredCuisine,
        maxCalories: maxCalories,
      );
      if (resp.isSuccess && resp.data != null) {
        recipeTaskId.value = resp.data!['task_id'] as String? ?? '';
        recipeTaskStatus.value = resp.data!['status'] as String? ?? 'pending';
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e) {
      errorMessage.value = '任务提交失败，请检查网络';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// 查询食谱任务结果
  Future<void> pollRecipeTask() async {
    if (recipeTaskId.value.isEmpty) return;
    try {
      final resp = await _service.getRecipeTask(recipeTaskId.value);
      if (resp.isSuccess && resp.data != null) {
        recipeTaskStatus.value =
            resp.data!['status'] as String? ?? recipeTaskStatus.value;
        if (recipeTaskStatus.value == 'success') {
          recipeResult.value = resp.data!['result'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {
      // 静默失败，等用户手动刷新
    }
  }

  /// 即将过期的食材（7天内）
  List<FridgeItemModel> get expiringItems =>
      items.where((i) => i.isExpiringSoon).toList();
}