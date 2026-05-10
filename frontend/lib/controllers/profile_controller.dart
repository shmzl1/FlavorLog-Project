import 'package:get/get.dart';

class ProfileController extends GetxController {
  final RxString nickname = '演示用户'.obs;
  final RxString healthGoal = '保持体态（keep_fit）'.obs;

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
