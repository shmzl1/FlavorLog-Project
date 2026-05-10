import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../components/section_card.dart';
import '../../components/tag_chip.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: Obx(() {
        final showName = authController.nickname.value.isNotEmpty
            ? authController.nickname.value
            : profileController.nickname.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.person, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          showName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '健康目标：${profileController.healthGoal.value}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '饮食偏好',
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: profileController.preferenceTags
                    .map((e) => TagChip(label: e))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '忌口 / 过敏',
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: profileController.allergyTags
                    .map((e) => TagChip(label: e, color: Colors.orange))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '本周记录情况',
              child: Row(
                children: [
                  Expanded(
                    child: _CountTile(
                      title: '本周记录次数',
                      value: profileController.weeklyRecordCount.value.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountTile(
                      title: '连续记录天数',
                      value: '${profileController.streakDays.value} 天',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: '设置',
              child: Column(
                children: const [
                  _SettingTile(title: '账号资料', icon: Icons.badge_outlined),
                  _SettingTile(title: '健康目标', icon: Icons.flag_outlined),
                  _SettingTile(title: '饮食偏好', icon: Icons.restaurant_menu),
                  _SettingTile(title: '关于知味志', icon: Icons.info_outline),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              onPressed: () {
                authController.logout();
                Get.offAllNamed(AppRoutes.auth);
              },
              icon: const Icon(Icons.logout),
              label: const Text('退出登录'),
            ),
          ],
        );
      }),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title 功能将在联调阶段接入')),
        );
      },
    );
  }
}
