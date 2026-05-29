import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../services/api/api_client.dart';
import '../services/api/api_endpoints.dart';
import '../services/api/token_storage.dart';

import 'home_controller.dart';
import 'fridge_controller.dart';
import 'food_record_controller.dart';
import 'health_report_controller.dart';
import 'profile_controller.dart';

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

  /// App 启动时恢复登录态（向后端验证 token 是否仍有效）
  Future<void> restoreSession() async {
    final saved = await TokenStorage.getToken();
    if (saved == null || saved.isEmpty) {
      isLoggedIn.value = false;
      return;
    }
    // 向后端验证 token 是否仍有效
    try {
      final resp = await _client.get(ApiEndpoints.me);
      final body = resp.data as Map<String, dynamic>?;
      if (body != null && body['code'] == 0) {
        token.value = saved;
        final user = body['data'] as Map<String, dynamic>? ?? {};
        nickname.value = (user['nickname'] as String?) ?? '用户';
        isLoggedIn.value = true;
        refreshAllControllersData();
      } else {
        await TokenStorage.clearToken();
        isLoggedIn.value = false;
      }
    } catch (_) {
      // 网络不通时保守地沿用本地 token，避免离线时反复跳到登录页
      token.value = saved;
      isLoggedIn.value = true;
    }
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
        refreshAllControllersData();
        return true;
      } else {
        errorMessage.value = body['message'] as String? ?? '登录失败';
        return false;
      }
    } on DioException catch (e) {
      errorMessage.value = _extractDetail(e, '登录失败');
      return false;
    } catch (e) {
      errorMessage.value = '网络请求失败，请检查连接';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 是否是11位中国大陆手机号
  static bool isChinesePhone(String s) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(s);
  }

  /// 注册（调用真实后端）
  Future<bool> register({
    required String nickname,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    clearError();

    if (nickname.trim().isEmpty) {
      errorMessage.value = '昵称不能为空';
      return false;
    }
    if (email.trim().isEmpty) {
      errorMessage.value = '账号不能为空';
      return false;
    }
    // 校验格式：邮箱 or 11位中国大陆手机号
    final acc = email.trim();
    final isPhone = isChinesePhone(acc);
    final isEmail = acc.contains('@');
    if (!isPhone && !isEmail) {
      errorMessage.value = '请输入有效的邮箱或11位中国大陆手机号';
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
      final acc = email.trim();
      final isPhone = isChinesePhone(acc);
      final Map<String, dynamic> payload = {
        'username': acc,
        'password': password,
        'nickname': nickname.trim(),
      };
      if (isPhone) {
        payload['phone'] = acc;
      } else {
        payload['email'] = acc;
      }
      final resp = await _client.post(
        ApiEndpoints.register,
        data: payload,
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
        refreshAllControllersData();
        return true;
      }
      errorMessage.value = body['message'] as String? ?? '注册失败';
      return false;
    } on DioException catch (e) {
      errorMessage.value = _extractDetail(e, '注册失败');
      return false;
    } catch (e) {
      errorMessage.value = '网络请求失败，请检查连接';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 从 DioException 安全提取后端返回的错误信息
  /// 后端统一格式：{"code":..., "message":"...", "errors":[{"field":"...","reason":"..."}]}
  String _extractDetail(DioException e, String fallback) {
    dynamic data = e.response?.data;

    // 响应体是原始字符串时先尝试解析
    if (data is String && data.isNotEmpty) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }

    if (data is Map) {
      // 1. 业务错误：message 字段（如"该手机号已经被注册"）
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty && msg != '参数错误') return msg;

      // 2. 参数校验错误：errors[0].reason（如"手机号格式不正确"）
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) {
          final reason = first['reason'];
          if (reason is String && reason.isNotEmpty) return reason;
        }
      }

      // 3. 兜底用 message
      if (msg is String && msg.isNotEmpty) return msg;
    }

    if (e.response == null) return '网络请求失败，请检查连接';
    return fallback;
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

  /// 登录或注册成功后，主动刷新各个持久控制器的状态，防止其界面显示老旧/空白数据
  void refreshAllControllersData() {
    // 1. 刷新首页看板与用户名
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      homeCtrl.username.value = nickname.value;
      homeCtrl.loadDashboard();
    }
    // 2. 刷新冰箱物品
    if (Get.isRegistered<FridgeController>()) {
      Get.find<FridgeController>().loadItems();
    }
    // 3. 刷新饮食记录
    if (Get.isRegistered<FoodRecordController>()) {
      Get.find<FoodRecordController>().loadRecords();
    }
    // 4. 刷新健康周报与红黑榜
    if (Get.isRegistered<HealthReportController>()) {
      final hrCtrl = Get.find<HealthReportController>();
      hrCtrl.loadBlacklist();
      hrCtrl.loadWeeklyReport();
      hrCtrl.loadFeedbacks();
    }
    // 5. 刷新个人中心的用户名
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().nickname.value = nickname.value;
    }
  }
}
