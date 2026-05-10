import 'package:dio/dio.dart';

import '../../models/food_record_model.dart';
import '../../models/api_response.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class FoodRecordService {
  FoodRecordService._();
  static final FoodRecordService instance = FoodRecordService._();

  final ApiClient _client = ApiClient.instance;

  /// 新增饮食记录 POST /food-records
  Future<ApiResponse<FoodRecordModel>> createRecord({
    required String mealType,
    required String recordTime,
    required String sourceType,
    String? description,
    required List<FoodItemModel> items,
  }) async {
    final body = {
      'meal_type': mealType,
      'record_time': recordTime,
      'source_type': sourceType,
      if (description != null) 'description': description,
      'items': items.map((e) => e.toJson()).toList(),
    };
    final resp = await _client.post(ApiEndpoints.foodRecords, data: body);
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => FoodRecordModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// 获取饮食记录列表 GET /food-records
  Future<ApiResponse<Map<String, dynamic>>> getRecords({
    int page = 1,
    int pageSize = 10,
    String? startDate,
    String? endDate,
    String? mealType,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (mealType != null) 'meal_type': mealType,
    };
    final resp =
        await _client.get(ApiEndpoints.foodRecords, queryParameters: params);
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => raw as Map<String, dynamic>,
    );
  }

  /// 获取单条饮食记录 GET /food-records/{record_id}
  Future<ApiResponse<FoodRecordModel>> getRecord(int recordId) async {
    final resp = await _client.get('${ApiEndpoints.foodRecords}/$recordId');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => FoodRecordModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// 修改饮食记录 PUT /food-records/{record_id}
  Future<ApiResponse<FoodRecordModel>> updateRecord({
    required int recordId,
    required String mealType,
    required String recordTime,
    required String sourceType,
    String? description,
    required List<FoodItemModel> items,
  }) async {
    final body = {
      'meal_type': mealType,
      'record_time': recordTime,
      'source_type': sourceType,
      if (description != null) 'description': description,
      'items': items.map((e) => e.toJson()).toList(),
    };
    final resp = await _client.put(
      '${ApiEndpoints.foodRecords}/$recordId',
      data: body,
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => FoodRecordModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  /// 删除饮食记录 DELETE /food-records/{record_id}
  Future<ApiResponse<Map<String, dynamic>>> deleteRecord(int recordId) async {
    final resp =
        await _client.delete('${ApiEndpoints.foodRecords}/$recordId');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => raw as Map<String, dynamic>,
    );
  }

  /// 上传图片 POST /uploads/image
  Future<ApiResponse<Map<String, dynamic>>> uploadImage(
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'scene': 'food',
    });
    final resp = await _client.dio.post<dynamic>(
      ApiEndpoints.uploadImage,
      data: formData,
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => raw as Map<String, dynamic>,
    );
  }

  /// 图片识别生成饮食记录草稿 POST /food-records/photo-recognition
  Future<ApiResponse<PhotoRecognitionDraft>> photoRecognition({
    required int fileId,
    required String mealType,
    required String recordTime,
  }) async {
    final body = {
      'file_id': fileId,
      'meal_type': mealType,
      'record_time': recordTime,
    };
    final resp = await _client.post(
      '${ApiEndpoints.foodRecords}/photo-recognition',
      data: body,
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => PhotoRecognitionDraft.fromJson(raw as Map<String, dynamic>),
    );
  }
}
