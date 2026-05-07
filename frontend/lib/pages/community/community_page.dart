import 'package:flutter/material.dart';

import '../../components/placeholder_page.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '社区动态',
      description: '这里由黄钧负责前端 UI，后端由唐丞杰和林宸宇协调：动态、评论、点赞、Fork、口味搭子。',
    );
  }
}