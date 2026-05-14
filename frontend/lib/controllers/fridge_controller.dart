import 'package:flutter/foundation.dart'; // 用于 debugPrint 打印日志
import 'package:get/get.dart';

import '../models/fridge_item_model.dart';
import '../services/api/fridge_service.dart';

/// [FridgeController] 负责管理“赛博冰箱”页面的所有状态与业务逻辑。
/// 包括食材列表的加载、新增、删除，以及 AI 智能食谱生成任务的提交与进度轮询。
class FridgeController extends GetxController {
  final FridgeService _service = FridgeService.instance;

  // ── 响应式状态变量 ──
  final RxBool isLoading = false.obs;       // 列表加载状态
  final RxBool isSubmitting = false.obs;    // 表单提交状态
  final RxList<FridgeItemModel> items = <FridgeItemModel>[].obs; // 冰箱内的食材列表
  final RxString errorMessage = ''.obs;     // 错误提示信息

  // ── AI 食谱生成相关状态 ──
  final RxString recipeTaskId = ''.obs;     // AI 异步任务 ID
  final RxString recipeTaskStatus = ''.obs; // 任务状态 (pending, success, failure 等)
  final Rx<Map<String, dynamic>?> recipeResult = Rx<Map<String, dynamic>?>(null); // AI 生成的食谱数据

  @override
  void onInit() {
    super.onInit();
    // 页面进入时立即拉取冰箱食材数据
    loadItems();
  }

  /// [loadItems] 获取冰箱食材列表。
  /// 【核心修复】：由于我们在 Service 层已经处理好了数据解析（ApiResponse<List<FridgeItemModel>>），
  /// 现在 resp.data 直接就是 List 类型，不再需要手动从 Map 里提取 'items' 字段，彻底解决了类型转换崩溃问题。
  Future<void> loadItems() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final resp = await _service.getItems(pageSize: 100);
      if (resp.isSuccess && resp.data != null) {
        // 直接将处理好的模型列表赋值给响应式变量
        items.assignAll(resp.data!);
      } else {
        errorMessage.value = resp.message;
      }
    } catch (e, stackTrace) {
      // 记录真实报错，方便在 Flutter 控制台排查
      debugPrint('==== 赛博冰箱加载崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      
      errorMessage.value = '加载失败: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// [createItem] 手动新增冰箱食材。
  /// 提交成功后会将被新增的对象直接插入本地列表顶部，实现即时刷新的视觉效果。
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
        // 无需重新拉取接口，直接本地插入
        items.insert(0, resp.data!);
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('==== 新增冰箱食材崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      
      errorMessage.value = '提交失败: $e';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// [deleteItem] 删除指定的食材记录。
  Future<bool> deleteItem(int itemId) async {
    errorMessage.value = '';
    try {
      final resp = await _service.deleteItem(itemId);
      if (resp.isSuccess) {
        // 同步移除本地内存中的数据
        items.removeWhere((i) => i.id == itemId);
        return true;
      } else {
        errorMessage.value = resp.message;
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('==== 删除冰箱食材崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      
      errorMessage.value = '删除失败: $e';
      return false;
    }
  }

  /// [submitRecipeTask] 提交 AI 食谱生成请求。
  /// 此操作会触发后端的长耗时任务，后端会立即返回一个任务 ID 供后续轮询。
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
    } catch (e, stackTrace) {
      debugPrint('==== 提交食谱任务崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');
      
      errorMessage.value = '任务提交失败: $e';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// [pollRecipeTask] 定时查询食谱任务的执行进度。
  /// 只有当任务状态变为 'success' 时，才会解析并保存食谱结果。
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
    } catch (e, stackTrace) {
      // 轮询失败通常不打断用户，仅在控制台记录
      debugPrint('==== 轮询食谱任务崩溃 ====');
      debugPrint('错误信息: $e');
    }
  }

  /// [expiringItems] 计算属性：过滤并返回冰箱中 7 天内即将过期的所有食材。
  List<FridgeItemModel> get expiringItems =>
      items.where((i) => i.isExpiringSoon).toList();
}