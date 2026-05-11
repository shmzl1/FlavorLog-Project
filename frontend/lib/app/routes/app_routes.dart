import 'package:get/get.dart';

import '../../pages/auth/auth_page.dart';
import '../../pages/home/home_page.dart';
import '../../pages/community/community_page.dart';
import '../../pages/profile/profile_page.dart';
import '../../pages/food_record/food_record_page.dart';
import '../../pages/cyber_fridge/cyber_fridge_page.dart';
import '../../pages/health_report/health_report_page.dart';

class AppRoutes {
  static const String auth = '/auth';
  static const String home = '/home';
  static const String foodRecord = '/food-record';
  static const String cyberFridge = '/cyber-fridge';
  static const String healthReport = '/health-report';
  static const String community = '/community';
  static const String profile = '/profile';

  static final List<GetPage<dynamic>> pages = [
    GetPage(name: auth, page: () => const AuthPage()),
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: foodRecord, page: () => const FoodRecordPage()),
    GetPage(name: cyberFridge, page: () => const CyberFridgePage()),
    GetPage(name: healthReport, page: () => const HealthReportPage()),
    GetPage(name: community, page: () => const CommunityPage()),
    GetPage(name: profile, page: () => const ProfilePage()),
  ];
}