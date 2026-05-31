import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';
import '../services/api/user_service.dart';

class ProfileController extends GetxController {
  final RxString nickname = '加载中...'.obs;
  final RxString healthGoal = '保持体态'.obs;
  final RxString phone = '未绑定手机号'.obs;
  final RxString email = '未绑定邮箱'.obs;
  final RxList<String> preferenceTags = <String>[].obs;
  final RxList<String> allergyTags = <String>[].obs;

  // Mock fallback defaults; real API should overwrite these when available.
  final RxInt checkinDays = 14.obs;
  final RxInt foodRecordCount = 32.obs;
  final RxInt awardCount = 128.obs;
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
      nickname.value = (data['nickname'] ?? data['username'] ?? '美食探索家').toString();
      final phoneRaw = data['phone']?.toString() ?? '';
      if (phoneRaw.isNotEmpty) phone.value = phoneRaw;
      final emailRaw = data['email']?.toString() ?? '';
      if (emailRaw.isNotEmpty) email.value = emailRaw;
      if (data['diet_preference'] is List) {
        preferenceTags.value = List<String>.from(data['diet_preference'] as List);
      }
      if (data['allergens'] is List) {
        allergyTags.value = List<String>.from(data['allergens'] as List);
      }
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().nickname.value = nickname.value;
      }
    } else {
      nickname.value = '美食探索家';
    }

    await loadProfileStats();
    isLoading.value = false;
  }

  Future<void> loadProfileStats() async {
    try {
      final stats = await UserService.instance.getMyStats();
      if (stats == null) {
        debugPrint('[ProfileController] loadProfileStats fallback: stats is null');
        return;
      }
      checkinDays.value = (stats['checkin_days'] as int?) ?? checkinDays.value;
      foodRecordCount.value = (stats['food_record_count'] as int?) ?? foodRecordCount.value;
      awardCount.value = (stats['award_count'] as int?) ?? awardCount.value;
      weeklyRecordCount.value = (stats['weekly_record_count'] as int?) ?? weeklyRecordCount.value;
      streakDays.value = (stats['streak_days'] as int?) ?? streakDays.value;
    } catch (e, st) {
      debugPrint('[ProfileController] loadProfileStats error: $e');
      debugPrint('$st');
    }
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
      if (newNickname != null) nickname.value = newNickname;
      if (newPhone != null) phone.value = newPhone;
      if (newEmail != null) email.value = newEmail;
      if (newDiet != null) preferenceTags.value = newDiet;
      if (newAllergens != null) allergyTags.value = newAllergens;
      if (Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().nickname.value = nickname.value;
      }
    }
    isLoading.value = false;
    return success;
  }
}
