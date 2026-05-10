import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxString welcomeText = '你好，欢迎回来'.obs;
  final RxString todaySummary = '今天已记录 2 餐，营养结构较均衡。'.obs;

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
}
