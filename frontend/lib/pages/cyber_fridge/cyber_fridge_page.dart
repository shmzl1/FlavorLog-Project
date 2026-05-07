import 'package:flutter/material.dart';

import '../../components/placeholder_page.dart';

class CyberFridgePage extends StatelessWidget {
  const CyberFridgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '赛博冰箱',
      description: '这里由刘子恒负责前端页面，焦思源负责后端接口：食材管理、生成食谱任务、查询推荐结果。',
    );
  }
}