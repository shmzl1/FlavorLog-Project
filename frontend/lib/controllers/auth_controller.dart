import 'package:get/get.dart';

class AuthController extends GetxController {
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString token = ''.obs;
  final RxString nickname = ''.obs;
  final RxString errorMessage = ''.obs;

  Future<bool> loginWithMock({
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
    await Future<void>.delayed(const Duration(milliseconds: 700));

    isLoggedIn.value = true;
    token.value = 'mock_token';
    nickname.value = '演示用户';
    isLoading.value = false;
    return true;
  }

  Future<bool> registerWithMock({
    required String nickname,
    required String account,
    required String password,
    required String confirmPassword,
  }) async {
    clearError();

    if (nickname.trim().isEmpty) {
      errorMessage.value = '昵称不能为空';
      return false;
    }
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
    if (confirmPassword != password) {
      errorMessage.value = '两次密码不一致';
      return false;
    }

    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 800));

    isLoggedIn.value = true;
    token.value = 'mock_token';
    this.nickname.value = nickname.trim();
    isLoading.value = false;
    return true;
  }

  void clearError() {
    errorMessage.value = '';
  }

  void logout() {
    isLoggedIn.value = false;
    isLoading.value = false;
    token.value = '';
    nickname.value = '';
    clearError();
  }
}
