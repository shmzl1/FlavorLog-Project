import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginAccountCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  final _registerNicknameCtrl = TextEditingController();
  final _registerAccountCtrl = TextEditingController();
  final _registerPasswordCtrl = TextEditingController();
  final _registerConfirmCtrl = TextEditingController();

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) {
          _authController.clearError();
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginAccountCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _registerNicknameCtrl.dispose();
    _registerAccountCtrl.dispose();
    _registerPasswordCtrl.dispose();
    _registerConfirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知味志 FlavorLog'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '登录'),
            Tab(text: '注册'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                '欢迎来到你的饮食健康管家',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Obx(() {
              final msg = _authController.errorMessage.value;
              if (msg.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.24)),
                ),
                child: Text(msg, style: const TextStyle(color: Colors.red)),
              );
            }),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(context),
                  _buildRegisterForm(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _loginAccountCtrl,
              decoration: const InputDecoration(
                labelText: '手机号或邮箱',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '账号不能为空';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _loginPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '密码不能为空';
                }
                if (value.length < 6) {
                  return '密码长度至少 6 位';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Obx(() {
              final loading = _authController.isLoading.value;
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : _submitLogin,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('登录'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _registerNicknameCtrl,
              decoration: const InputDecoration(
                labelText: '昵称',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '昵称不能为空';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registerAccountCtrl,
              decoration: const InputDecoration(
                labelText: '手机号或邮箱',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '账号不能为空';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registerPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '密码不能为空';
                }
                if (value.length < 6) {
                  return '密码长度至少 6 位';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registerConfirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认密码',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '确认密码不能为空';
                }
                if (value != _registerPasswordCtrl.text) {
                  return '两次密码不一致';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Obx(() {
              final loading = _authController.isLoading.value;
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: loading ? null : _submitRegister,
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('注册并进入'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!(_loginFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final ok = await _authController.loginWithMock(
      account: _loginAccountCtrl.text.trim(),
      password: _loginPasswordCtrl.text,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录成功，欢迎回来！')),
      );
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _submitRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final ok = await _authController.registerWithMock(
      nickname: _registerNicknameCtrl.text.trim(),
      account: _registerAccountCtrl.text.trim(),
      password: _registerPasswordCtrl.text,
      confirmPassword: _registerConfirmCtrl.text,
    );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，欢迎加入知味志！')),
      );
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
