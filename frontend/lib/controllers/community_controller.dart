import 'package:get/get.dart';

class CommunityController extends GetxController {
  final RxBool isLoading = false.obs;

  Future<void> loadPosts() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    isLoading.value = false;
  }
}