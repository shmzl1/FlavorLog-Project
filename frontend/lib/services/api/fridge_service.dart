import '../../models/fridge_item_model.dart';
import '../../models/api_response.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class FridgeService {
  FridgeService._();
  static final FridgeService instance = FridgeService._();

  final ApiClient _client = ApiClient.instance;

  /// 新增冰箱食材 POST /fridge/items
  Future<ApiResponse<FridgeItemModel>> createItem({
    required String name,
    String? category,
    required double quantity,
    String? unit,
    double? weightG,
    String? expireDate,
    String? storageLocation,
    String? remark,
  }) async {
    final body = {
      'name': name,
      if (category != null) 'category': category,
      'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (weightG != null) 'weight_g': weightG,
      if (expireDate != null) 'expire_date': expireDate,
      if (storageLocation != null) 'storage_location': storageLocation,
      if (remark != null) 'remark': remark,
    };
    final resp = await _client.post(ApiEndpoints.fridgeItems, data: body);
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => FridgeItemModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// 获取冰箱食材列表 GET /fridge/items
  Future<ApiResponse<Map<String, dynamic>>> getItems({
    int page = 1,
    int pageSize = 20,
    String? category,
    int? expiringDays,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (category != null) 'category': category,
      if (expiringDays != null) 'expiring_days': expiringDays,
    };
    final resp =
        await _client.get(ApiEndpoints.fridgeItems, queryParameters: params);
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }

  /// 修改冰箱食材 PUT /fridge/items/{item_id}
  Future<ApiResponse<FridgeItemModel>> updateItem(
    int itemId,
    FridgeItemModel item,
  ) async {
    final resp = await _client.put(
      '${ApiEndpoints.fridgeItems}/$itemId',
      data: item.toJson(),
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => FridgeItemModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// 删除冰箱食材 DELETE /fridge/items/{item_id}
  Future<ApiResponse<Map<String, dynamic>>> deleteItem(int itemId) async {
    final resp =
        await _client.delete('${ApiEndpoints.fridgeItems}/$itemId');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }

  /// 提交食谱生成任务 POST /fridge/recipe-tasks
  Future<ApiResponse<Map<String, dynamic>>> createRecipeTask({
    String? target,
    List<String>? avoidIngredients,
    String? preferredCuisine,
    int? maxCalories,
    bool useExpiringFirst = true,
  }) async {
    final body = {
      if (target != null) 'target': target,
      if (avoidIngredients != null) 'avoid_ingredients': avoidIngredients,
      if (preferredCuisine != null) 'preferred_cuisine': preferredCuisine,
      if (maxCalories != null) 'max_calories': maxCalories,
      'use_expiring_first': useExpiringFirst,
    };
    final resp = await _client.post('/fridge/recipe-tasks', data: body);
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }

  /// 查询食谱任务结果 GET /fridge/recipe-tasks/{task_id}
  Future<ApiResponse<Map<String, dynamic>>> getRecipeTask(
    String taskId,
  ) async {
    final resp = await _client.get('/fridge/recipe-tasks/$taskId');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }
}
