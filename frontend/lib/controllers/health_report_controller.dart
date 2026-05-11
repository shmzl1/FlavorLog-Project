import 'package:get/get.dart';

class HealthReportController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> blackItems = <Map<String, dynamic>>[].obs;

  Future<void> loadMockBlacklist() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    blackItems.assignAll([
      {
        'food_name': '牛奶',
        'reason': '与腹胀反馈存在较高关联',
        'confidence': 0.76,
      },
    ]);

    isLoading.value = false;
  }
}