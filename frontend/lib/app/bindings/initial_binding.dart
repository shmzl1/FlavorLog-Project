import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/community_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/food_record_controller.dart';
import '../../controllers/fridge_controller.dart';
import '../../controllers/health_report_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(CommunityController(), permanent: true);
    Get.put(ProfileController(), permanent: true);

    Get.put(FoodRecordController(), permanent: true);
    Get.put(FridgeController(), permanent: true);
    Get.put(HealthReportController(), permanent: true);
  }
}