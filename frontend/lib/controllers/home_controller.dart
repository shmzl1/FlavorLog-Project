import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/food_record_model.dart';
import '../services/api/food_record_service.dart';

class HomeController extends GetxController {
  final RxString username = ''.obs;

  final RxString welcomeText = '你好，欢迎回来'.obs;
  final RxString todaySummary = '今天已记录 2 餐，营养结构较均衡。'.obs;
  final RxString aiTip =
      '检测到你今天蛋白质摄入偏低，晚餐可以优先选择鸡胸肉、鸡蛋、豆腐等高蛋白食材。'.obs;

  static const double targetCalories = 2000;
  static const double targetCarbohydrateG = 250;
  static const double targetProteinG = 90;
  static const double targetFatG = 65;

  final RxDouble totalCalories = 1560.0.obs;
  final RxDouble totalProteinG = 86.0.obs;
  final RxDouble totalFatG = 42.0.obs;
  final RxDouble totalCarbohydrateG = 120.0.obs;
  final RxInt mealCount = 2.obs;
  final RxDouble remainingCalories = 1340.0.obs;
  final RxDouble calorieProgress = 0.68.obs;
  final RxDouble carbProgress = 0.48.obs;
  final RxDouble proteinProgress = 0.72.obs;
  final RxDouble fatProgress = 0.64.obs;

  String get remainingCaloriesText =>
      remainingCalories.value.toStringAsFixed(0);
  String get carbText =>
      '${totalCarbohydrateG.value.toStringAsFixed(0)}/${targetCarbohydrateG.toStringAsFixed(0)} 克';
  String get proteinText =>
      '${totalProteinG.value.toStringAsFixed(0)}/${targetProteinG.toStringAsFixed(0)} 克';
  String get fatText =>
      '${totalFatG.value.toStringAsFixed(0)}/${targetFatG.toStringAsFixed(0)} 克';

  final RxList<Map<String, dynamic>> stats = <Map<String, dynamic>>[
    {
      'title': '今日热量',
      'value': '1560',
      'unit': 'kcal',
      'icon': 'local_fire_department',
    },
    {
      'title': '蛋白质',
      'value': '86',
      'unit': 'g',
      'icon': 'fitness_center',
    },
    {
      'title': '饮水',
      'value': '1450',
      'unit': 'ml',
      'icon': 'water_drop',
    },
    {
      'title': '健康评分',
      'value': '88',
      'unit': '分',
      'icon': 'favorite',
    },
  ].obs;

  final RxList<Map<String, dynamic>> featureEntries = <Map<String, dynamic>>[
    {
      'title': '饮食记录',
      'subtitle': '记录每一餐并查看营养汇总',
      'route': '/food-record',
      'icon': 'restaurant_menu',
    },
    {
      'title': '赛博冰箱',
      'subtitle': '管理库存食材并生成食谱',
      'route': '/cyber-fridge',
      'icon': 'kitchen',
    },
    {
      'title': '健康报告',
      'subtitle': '查看周报、红黑榜与反馈',
      'route': '/health-report',
      'icon': 'monitor_heart',
    },
    {
      'title': '社区动态',
      'subtitle': '分享饮食日常和互动交流',
      'route': '/community',
      'icon': 'forum',
    },
    {
      'title': '个人中心',
      'subtitle': '管理个人资料和饮食偏好',
      'route': '/profile',
      'icon': 'person',
    },
  ].obs;

  final RxList<String> healthTips = <String>[
    '晚餐可适当减少精制碳水，增加蔬菜比例。',
    '今天蛋白质摄入表现不错，保持当前节奏。',
    '记得在睡前 2 小时内避免高糖零食。',
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  void loadMockDashboard() {
    totalCalories.value = 1560;
    totalProteinG.value = 86;
    totalFatG.value = 42;
    totalCarbohydrateG.value = 120;
    mealCount.value = 2;

    remainingCalories.value = 1340;
    calorieProgress.value = 0.68;
    carbProgress.value = 0.48;
    proteinProgress.value = 0.72;
    fatProgress.value = 0.64;

    todaySummary.value = '今天已记录 2 餐，营养结构较均衡。';
    aiTip.value =
        '检测到你今天蛋白质摄入偏低，晚餐可以优先选择鸡胸肉、鸡蛋、豆腐等高蛋白食材。';

    stats.assignAll([
      {
        'title': '今日热量',
        'value': '1560',
        'unit': 'kcal',
        'icon': 'local_fire_department',
      },
      {
        'title': '蛋白质',
        'value': '86',
        'unit': 'g',
        'icon': 'fitness_center',
      },
      {
        'title': '饮水',
        'value': '1450',
        'unit': 'ml',
        'icon': 'water_drop',
      },
      {
        'title': '健康评分',
        'value': '88',
        'unit': '分',
        'icon': 'favorite',
      },
    ]);
  }

  Future<void> loadDashboard() async {
    // 先加载 mock，保证页面立即可用
    loadMockDashboard();

    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final resp = await FoodRecordService.instance.getRecords(
        page: 1,
        pageSize: 50,
        startDate: todayStart.toIso8601String(),
        endDate: todayEnd.toIso8601String(),
      );

      if (!resp.isSuccess) {
        debugPrint(
          '[HomeController] loadDashboard fallback(mock): getRecords failed, code=${resp.code}, message=${resp.message}',
        );
        return;
      }

      final records = resp.data;
      if (records == null || records.isEmpty) {
        debugPrint(
          '[HomeController] loadDashboard fallback(mock): no records today',
        );
        return;
      }

      _applyRecords(records);
    } catch (e, st) {
      debugPrint('[HomeController] loadDashboard exception: $e');
      debugPrint('$st');
    }
  }

  void _applyRecords(List<FoodRecordModel> records) {
    final sumCalories = records.fold<double>(
      0,
      (prev, r) => prev + r.totalCalories,
    );
    final sumProtein = records.fold<double>(
      0,
      (prev, r) => prev + r.totalProteinG,
    );
    final sumFat = records.fold<double>(
      0,
      (prev, r) => prev + r.totalFatG,
    );
    final sumCarb = records.fold<double>(
      0,
      (prev, r) => prev + r.totalCarbohydrateG,
    );

    totalCalories.value = sumCalories;
    totalProteinG.value = sumProtein;
    totalFatG.value = sumFat;
    totalCarbohydrateG.value = sumCarb;
    mealCount.value = records.length;

    remainingCalories.value =
        (targetCalories - sumCalories).clamp(0, double.infinity).toDouble();
    calorieProgress.value = _clampProgress(sumCalories / targetCalories);
    carbProgress.value = _clampProgress(sumCarb / targetCarbohydrateG);
    proteinProgress.value = _clampProgress(sumProtein / targetProteinG);
    fatProgress.value = _clampProgress(sumFat / targetFatG);

    todaySummary.value =
        '今天已记录 ${records.length} 餐，累计摄入 ${sumCalories.toStringAsFixed(0)} 千卡。';
    aiTip.value = _buildAiTip(
      totalCalories: sumCalories,
      totalProtein: sumProtein,
    );

    final healthScore = _calcHealthScore(calorieProgress.value);
    stats.assignAll([
      {
        'title': '今日热量',
        'value': sumCalories.toStringAsFixed(0),
        'unit': 'kcal',
        'icon': 'local_fire_department',
      },
      {
        'title': '蛋白质',
        'value': sumProtein.toStringAsFixed(0),
        'unit': 'g',
        'icon': 'fitness_center',
      },
      {
        'title': '饮水',
        'value': '1450',
        'unit': 'ml',
        'icon': 'water_drop',
      },
      {
        'title': '健康评分',
        'value': '$healthScore',
        'unit': '分',
        'icon': 'favorite',
      },
    ]);
  }

  double _clampProgress(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return value.clamp(0, 1).toDouble();
  }

  int _calcHealthScore(double calorieRate) {
    if (calorieRate <= 0.9) return 88;
    if (calorieRate <= 1.0) return 82;
    return 75;
  }

  String _buildAiTip({
    required double totalCalories,
    required double totalProtein,
  }) {
    if (totalProtein < targetProteinG * 0.6) {
      return '检测到你今天蛋白质摄入偏低，晚餐可以优先选择鸡胸肉、鸡蛋、豆腐等高蛋白食材。';
    }
    if (totalCalories >= targetCalories) {
      return '今天热量摄入已接近或超过目标，晚餐建议减少油炸食品和精制碳水。';
    }
    return '今天营养摄入整体较均衡，继续保持规律记录和适量运动。';
  }
}
