import 'package:flutter/material.dart';

import '../../components/placeholder_page.dart';

class HealthReportPage extends StatelessWidget {
  const HealthReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '健康报告',
      description: '这里由刘子恒负责前端页面，林宸宇负责后端接口：健康反馈、红黑榜、健康周报。',
    );
  }
}