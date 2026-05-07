import 'package:flutter/material.dart';

import '../../components/placeholder_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(
      title: '个人中心',
      description: '这里由黄钧负责：用户资料展示、健康目标展示、退出登录入口。',
    );
  }
}