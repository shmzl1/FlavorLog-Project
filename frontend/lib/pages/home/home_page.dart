import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildEntryButton(String title, String route) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知味志 FlavorLog'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '阶段一 MVP 功能入口',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildEntryButton('饮食记录', AppRoutes.foodRecord),
          _buildEntryButton('赛博冰箱', AppRoutes.cyberFridge),
          _buildEntryButton('健康报告', AppRoutes.healthReport),
          _buildEntryButton('社区动态', AppRoutes.community),
          _buildEntryButton('个人中心', AppRoutes.profile),
        ],
      ),
    );
  }
}