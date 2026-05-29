import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'auth_controller.dart';
import '../services/api/user_service.dart';

class ProfileController extends GetxController {
  final RxString nickname = '加载中...'.obs;
  final RxString healthGoal = '保持体态'.obs;
  final RxString phone = '未绑定手机号'.obs;
  final RxString email = '未绑定邮箱'.obs;
  final RxList<String> preferenceTags = <String>[].obs;
  final RxList<String> allergyTags = <String>[].obs;
  final RxInt weeklyRecordCount = 9.obs;
  final RxInt streakDays = 6.obs;
  
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService());
    }
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    isLoading.value = true;
    final data = await UserService.instance.getMe();
    if (data != null) {
      nickname.value = data['nickname'] ?? data['username'] ?? '美食探索家';
      if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
        phone.value = data['phone'];
      }
      if (data['email'] != null && data['email'].toString().isNotEmpty) {
        email.value = data['email'];
      }
      if (data['diet_preference'] != null) {
        preferenceTags.value = List<String>.from(data['diet_preference']);
      }
      if (data['allergens'] != null) {
        allergyTags.value = List<String>.from(data['allergens']);
      }
      
      // Update AuthController state if needed
      if (Get.isRegistered<AuthController>()) {
        final authCtrl = Get.find<AuthController>();
        authCtrl.nickname.value = nickname.value;
      }
    } else {
      // Fallback
      nickname.value = '美食探索家';
    }
    isLoading.value = false;
  }

  Future<bool> updateProfile({
    String? newNickname,
    String? newPhone,
    String? newEmail,
    List<String>? newDiet,
    List<String>? newAllergens,
  }) async {
    isLoading.value = true;
    
    final Map<String, dynamic> updateData = {};
    if (newNickname != null) updateData['nickname'] = newNickname;
    if (newPhone != null) updateData['phone'] = newPhone;
    if (newEmail != null) updateData['email'] = newEmail;
    if (newDiet != null) updateData['diet_preference'] = newDiet;
    if (newAllergens != null) updateData['allergens'] = newAllergens;

    if (updateData.isEmpty) {
      isLoading.value = false;
      return true;
    }

    final success = await UserService.instance.updateMe(updateData);
    if (success) {
      // Refresh local state
      if (newNickname != null) nickname.value = newNickname;
      if (newPhone != null) phone.value = newPhone;
      if (newEmail != null) email.value = newEmail;
      if (newDiet != null) preferenceTags.value = newDiet;
      if (newAllergens != null) allergyTags.value = newAllergens;
      
      // Sync to auth
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().nickname.value = nickname.value;
      }
    }
    isLoading.value = false;
    return success;
  }
}
