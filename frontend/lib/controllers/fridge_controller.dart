import 'package:get/get.dart';

class FridgeController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> items = <Map<String, dynamic>>[].obs;

  Future<void> loadMockItems() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));

    items.assignAll([
      {
        'id': 1,
        'name': '鸡胸肉',
        'category': 'meat',
        'quantity': 2,
        'unit': 'piece',
      },
    ]);

    isLoading.value = false;
  }
}