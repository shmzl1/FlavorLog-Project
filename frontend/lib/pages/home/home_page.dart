import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../components/feature_entry_card.dart';
import '../../components/section_card.dart';
import '../../components/stat_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  IconData _resolveIcon(String iconName) {
    const iconMap = {
      'local_fire_department': Icons.local_fire_department,
      'fitness_center': Icons.fitness_center,
      'water_drop': Icons.water_drop,
      'favorite': Icons.favorite,
      'restaurant_menu': Icons.restaurant_menu,
      'kitchen': Icons.kitchen,
      'monitor_heart': Icons.monitor_heart,
      'forum': Icons.forum,
      'person': Icons.person,
    };
    return iconMap[iconName] ?? Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('知味志 FlavorLog'),
        actions: [
          IconButton(
            tooltip: '个人中心',
            onPressed: () => Get.toNamed(AppRoutes.profile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Obx(() {
        final nickname = authController.nickname.value.isEmpty
            ? '同学'
            : authController.nickname.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '$nickname，${homeController.welcomeText.value}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              homeController.todaySummary.value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: '今日饮食摘要',
              child: Text(
                '三餐节奏稳定，蛋白质摄入较好。晚餐建议增加蔬菜和水分摄入。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '统计卡片',
              child: GridView.builder(
                itemCount: homeController.stats.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 110,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = homeController.stats[index];
                  return StatTile(
                    title: item['title'] as String,
                    value: item['value'] as String,
                    unit: item['unit'] as String,
                    icon: _resolveIcon(item['icon'] as String),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '功能入口',
              child: Column(
                children: homeController.featureEntries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FeatureEntryCard(
                      title: entry['title'] as String,
                      subtitle: entry['subtitle'] as String,
                      icon: _resolveIcon(entry['icon'] as String),
                      onTap: () => Get.toNamed(entry['route'] as String),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '今日健康建议',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: homeController.healthTips.map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(Icons.eco, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }
}
