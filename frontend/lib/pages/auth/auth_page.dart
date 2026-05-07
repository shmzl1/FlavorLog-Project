import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../components/placeholder_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderPage(
      title: '登录 / 注册',
      description: '这里后续实现用户登录、注册、Token 保存和进入首页逻辑。',
      actions: [
        FilledButton(
          onPressed: () => Get.offNamed(AppRoutes.home),
          child: const Text('临时进入首页'),
        ),
      ],
    );
  }
}