import 'package:get/get.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  final RxString nickname = '美食探索家'.obs;
  final RxString healthGoal = '保持体态（keep_fit）'.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<AuthController>()) {
      final authCtrl = Get.find<AuthController>();
      if (authCtrl.nickname.value.isNotEmpty) {
        nickname.value = authCtrl.nickname.value;
      }
    }
  }

  final RxList<String> preferenceTags = <String>[
    '高蛋白',
    '低糖',
    '清淡',
  ].obs;

  final RxList<String> allergyTags = <String>[
    '花生',
    '乳糖',
  ].obs;

  final RxInt weeklyRecordCount = 9.obs;
  final RxInt streakDays = 6.obs;
}
