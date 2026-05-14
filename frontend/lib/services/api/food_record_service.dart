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
  Future<ApiResponse<List<FoodRecordModel>>> getRecords({
    int page = 1,
    int pageSize = 50,
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
      (raw) => (raw as List<dynamic>)
          .map((e) => FoodRecordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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
    String filePath, {
    String scene = 'food',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'scene': scene,
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

  /// 上传视频 POST /uploads/video
  Future<ApiResponse<Map<String, dynamic>>> uploadVideo(
    String filePath, {
    String scene = 'food_scan',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'scene': scene,
    });
    final resp = await _client.dio.post<dynamic>(
      ApiEndpoints.uploadVideo,
      data: formData,
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => raw as Map<String, dynamic>,
    );
  }

  /// 上传音频 POST /uploads/audio
  Future<ApiResponse<Map<String, dynamic>>> uploadAudio(
    String filePath, {
    String scene = 'voice_note',
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'scene': scene,
    });
    final resp = await _client.dio.post<dynamic>(
      ApiEndpoints.uploadAudio,
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

  /// 视频极速录入 POST /recognition/video-fast-entry
  /// 上传视频，返回 AI 识别的饮食记录草稿列表（未保存到数据库）
  Future<ApiResponse<List<Map<String, dynamic>>>> videoFastEntry(
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        contentType: DioMediaType('video', 'mp4'),
      ),
    });
    final resp = await _client.dio.post<dynamic>(
      ApiEndpoints.videoFastEntry,
      data: formData,
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => (raw as List<dynamic>).cast<Map<String, dynamic>>(),
    );
  }
}
