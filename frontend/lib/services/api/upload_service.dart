import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'api_endpoints.dart';

class UploadService {
  UploadService._();
  static final UploadService instance = UploadService._();

  final ApiClient _client = ApiClient.instance;

  Future<String> uploadCommunityImage(XFile file) async {
    try {
      final formData = FormData.fromMap({
        'scene': 'community_post',
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name.isNotEmpty ? file.name : file.path.split(RegExp(r'[\\/]')).last,
        ),
      });

      final resp = await _client.dio.post<dynamic>(ApiEndpoints.uploadImage, data: formData);
      final body = resp.data as Map<String, dynamic>;
      final data = body['data'];
      if (body['code'] != 0 || data is! Map<String, dynamic>) {
        throw Exception(body['message'] as String? ?? '图片上传失败');
      }

      final rawUrl = data['file_url'] ?? data['url'] ?? data['path'];
      if (rawUrl is String && rawUrl.trim().isNotEmpty) {
        return rawUrl.trim();
      }
      throw Exception('图片上传成功但未返回图片地址');
    } catch (e, st) {
      debugPrint('[UploadService] upload community image failed: $e');
      debugPrint('$st');
      rethrow;
    }
  }
}

String resolveImageUrl(String url) {
  final clean = url.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return clean;
  }

  final apiBaseUrl = ApiEndpoints.baseUrl;
  final serverBaseUrl = apiBaseUrl.endsWith('/api/v1')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - '/api/v1'.length)
      : apiBaseUrl;

  if (clean.startsWith('/')) {
    return '$serverBaseUrl$clean';
  }
  return '$serverBaseUrl/$clean';
}
