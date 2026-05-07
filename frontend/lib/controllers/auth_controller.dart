import 'package:get/get.dart';

class AuthController extends GetxController {
  final RxBool isLoggedIn = false.obs;
  final RxString token = ''.obs;

  void setLoginState({
    required bool loggedIn,
    String? accessToken,
  }) {
    isLoggedIn.value = loggedIn;
    if (accessToken != null) {
      token.value = accessToken;
    }
  }

  void logout() {
    isLoggedIn.value = false;
    token.value = '';
  }
}