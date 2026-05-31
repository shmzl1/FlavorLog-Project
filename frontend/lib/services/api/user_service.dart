import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class UserService extends GetxService {
  static UserService get instance => Get.find<UserService>();

  Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.usersMe);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['code'] == 0 && body['data'] != null) {
          return body['data'];
        }
      }
    } catch (e) {
      debugPrint('[UserService] getMe error: $e');
    }
    return null;
  }

  Future<bool> updateMe(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.instance.put(
        ApiEndpoints.usersMe,
        data: data,
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['code'] == 0) {
          return true;
        } else {
          debugPrint('[UserService] updateMe failed: ${body['message']}');
        }
      } else {
        debugPrint('[UserService] updateMe status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[UserService] updateMe error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> getMyStats() async {
    try {
      final response = await ApiClient.instance.get(ApiEndpoints.usersMeStats);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body['code'] == 0 && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
        debugPrint('[UserService] getMyStats failed: ${body['message']}');
      } else {
        debugPrint('[UserService] getMyStats status code: ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('[UserService] getMyStats error: $e');
      debugPrint('$st');
    }
    return null;
  }
}
