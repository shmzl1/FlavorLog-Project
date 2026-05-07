import 'package:get/get.dart';

class FoodRecordController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> records = <Map<String, dynamic>>[].obs;

  Future<void> loadMockRecords() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    records.assignAll([
      {
        'id': 1,
        'meal_type': 'lunch',
        'description': '演示午餐记录',
        'total_calories': 520,
      },
    ]);

    isLoading.value = false;
  }
}