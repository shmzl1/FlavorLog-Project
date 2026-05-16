import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../services/api/api_client.dart';
import '../services/api/api_endpoints.dart';
import '../services/api/token_storage.dart';

class AuthController extends GetxController {
  final ApiClient _client = ApiClient.instance;

  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString token = ''.obs;
  final RxString nickname = ''.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    restoreSession();
  }

  /// App 启动时恢复登录态
  Future<void> restoreSession() async {
    final saved = await TokenStorage.getToken();
    if (saved != null && saved.isNotEmpty) {
      token.value = saved;
      isLoggedIn.value = true;
      return;
    }
    isLoggedIn.value = false;
  }

  /// 登录（调用真实后端）
  Future<bool> login({
    required String account,
    required String password,
  }) async {
    clearError();

    if (account.trim().isEmpty) {
      errorMessage.value = '账号不能为空';
      return false;
    }
    if (password.isEmpty) {
      errorMessage.value = '密码不能为空';
      return false;
    }
    if (password.length < 6) {
      errorMessage.value = '密码长度至少 6 位';
      return false;
    }

    isLoading.value = true;
    try {
      final resp = await _client.post(
        ApiEndpoints.login,
        data: {'account': account.trim(), 'password': password},
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['code'] == 0) {
        final data = body['data'] as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final user = data['user'] as Map<String, dynamic>? ?? {};
        await TokenStorage.saveToken(accessToken);
        token.value = accessToken;
        nickname.value = (user['nickname'] as String?) ?? '用户';
        isLoggedIn.value = true;
        return true;
      }
      errorMessage.value = body['message'] as String? ?? '登录失败';
      return false;
    } catch (e, stackTrace) {
      debugPrint('==== 登录崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');

      errorMessage.value = '登录失败: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 注册（调用真实后端）
  Future<bool> register({
    required String nickname,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    clearError();
    final emailInput = email.trim().toLowerCase();

    if (nickname.trim().isEmpty) {
      errorMessage.value = '昵称不能为空';
      return false;
    }
    if (emailInput.isEmpty) {
      errorMessage.value = '邮箱不能为空';
      return false;
    }
    if (!_isValidEmail(emailInput)) {
      errorMessage.value = '请输入合法邮箱，例如 test@example.com';
      return false;
    }
    if (password.isEmpty) {
      errorMessage.value = '密码不能为空';
      return false;
    }
    if (password.length < 6) {
      errorMessage.value = '密码长度至少 6 位';
      return false;
    }
    if (confirmPassword != password) {
      errorMessage.value = '两次密码不一致';
      return false;
    }

    isLoading.value = true;
    try {
      final username = emailInput.split('@').first;
      final resp = await _client.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': emailInput,
          'password': password,
          'nickname': nickname.trim(),
        },
      );
      final body = resp.data as Map<String, dynamic>;
      if (body['code'] == 0) {
        final data = body['data'] as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final user = data['user'] as Map<String, dynamic>? ?? {};
        await TokenStorage.saveToken(accessToken);
        token.value = accessToken;
        this.nickname.value = (user['nickname'] as String?) ?? nickname.trim();
        isLoggedIn.value = true;
        return true;
      }
      errorMessage.value = body['message'] as String? ?? '注册失败';
      return false;
    } on DioException catch (e, stackTrace) {
      debugPrint('==== 注册崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');

      final statusCode = e.response?.statusCode;
      if (statusCode == 422) {
        errorMessage.value = '注册信息格式不正确，请检查邮箱、密码和昵称';
        return false;
      }
      if (statusCode == 400) {
        final backendMessage = _extractBackendErrorMessage(e.response?.data);
        errorMessage.value = backendMessage ?? '注册失败，请检查账号信息';
        return false;
      }
      errorMessage.value = '注册失败，请稍后重试';
      return false;
    } catch (e, stackTrace) {
      debugPrint('==== 注册崩溃 ====');
      debugPrint('错误信息: $e');
      debugPrint('堆栈追踪: $stackTrace');

      errorMessage.value = '注册失败，请稍后重试';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  bool _isValidEmail(String input) {
    final pattern =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    return pattern.hasMatch(input);
  }

  String? _extractBackendErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  void clearError() {
    errorMessage.value = '';
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
    isLoggedIn.value = false;
    isLoading.value = false;
    token.value = '';
    nickname.value = '';
    clearError();
  }
}
