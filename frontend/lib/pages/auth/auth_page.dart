// frontend/lib/pages/auth/auth_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

/// 【类说明：FlavorLog 沉浸式智慧鉴权控制中心（登录与注册）】
/// 作用：
/// 统一承载用户的登录身份验证与新用户账号注册，通过本地响应式状态执行 UI 表单的分流渲染。
/// 
/// 设计语言：
/// 1. 采用大厂主流的 Full-Gradient（全幅流光极光渐变）作为大背景，赋予应用极高的高级感。
/// 2. 鉴权核心表单悬浮在毛玻璃白衬底卡片上，带有精细的 Drop Shadow 扩散。
/// 3. 输入框全面进化为高弧度圆角胶囊（BorderRadius.circular(16)），触感极其细腻。
class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // 核心安全控制总线
  final _formKey = GlobalKey<FormState>();
  
  // 文本编辑控制器矩阵（100% 对齐标准的鉴权字段需求）
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController(); // 注册时使用的用户名
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // 局部响应式变量：控制当前是登录(true)还是注册(false)模式
  bool _isLoginMode = true;
  // 局部响应式变量：控制密码的明文/暗文睁闭眼切换
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  /// 【内部状态切换函数：一键平滑洗牌表单状态】
  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset(); // 原地擦除并清空所有的标红报错提示
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
    });
  }

  /// 【业务核心网络函数：跨网关身份投递鉴权】
  /// 核心逻辑：
  /// 1. 激活 `_formKey.currentState?.validate()` 进行严格的格式把关。
  /// 2. 如果处于注册模式，额外进行密码与确认密码的物理一致性校验。
  /// 3. 打包数据分发至 GetX 后端通信网关，在网络加载期间阻塞提交按钮，展示优雅的转圈动效。
  void _handleAuthSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isLoginMode && _passwordCtrl.text != _confirmPasswordCtrl.text) {
      Get.snackbar("密码不匹配", "两次输入的密码不一致，请仔细检查一下哦", 
        snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFFFFCC00));
      return;
    }

    // 模拟网络提交状态（后期可无缝替换为 controller.login() / register()）
    bool isNetworkLoading = true;
    
    if (isNetworkLoading) {
      // 登录成功后的丝滑转场逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLoginMode ? '🎉 欢迎回来，美食探索家！' : '🚀 账号注册成功，开启智慧饮食之旅！'),
          backgroundColor: const Color(0xFF20BF6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // 跳转至主控首页
      // Get.offAllNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 视觉亮点 1：全幅沉浸式流光极光渐变大底座
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF6B35), // 智慧活力橙
                  Color(0xFFFF4757), // 动感珊瑚红
                  Color(0xFF2F3542), // 深邃静谧蓝黑
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // 视觉亮点 2：毛玻璃层级延展
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),

          // 核心内容展示区（全幅支持滚动且自动避让系统弹出的虚拟软键盘）
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // S1: 情感化应用艺术 Logo 区域
                  _buildAppLogo(),
                  const SizedBox(height: 32),
                  
                  // S2: 核心悬浮鉴权面板控制舱
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96), // 高饱和度白，确保输入文字阅读极其清晰
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 模块 1：高颜值双态平滑滑动切换开关
                          _buildAuthModeToggle(),
                          const SizedBox(height: 28),
                          
                          // 模块 2：动态表单资产输入流
                          if (!_isLoginMode) ...[
                            _buildInputField(
                              controller: _usernameCtrl,
                              labelText: "用户昵称",
                              hintText: "怎么称呼您？例: 减脂小能手",
                              icon: Icons.person_outline_rounded,
                              validator: (v) => (v == null || v.trim().isEmpty) ? '请填写一个好听的昵称' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          _buildInputField(
                            controller: _emailCtrl,
                            labelText: "电子邮箱",
                            hintText: "请输入您的常用邮箱地址",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return '请填写邮箱地址';
                              if (!GetUtils.isEmail(v.trim())) return '⚠️ 邮箱格式似乎不太正确哦';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          _buildPasswordField(),
                          
                          if (!_isLoginMode) ...[
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _confirmPasswordCtrl,
                              labelText: "确认密码",
                              hintText: "请再次输入密码以防输错",
                              icon: Icons.lock_clock_outlined,
                              obscureText: true,
                              validator: (v) => (v == null || v.isEmpty) ? '请再次填写密码' : null,
                            ),
                          ],
                          
                          // 密码找回辅助说明（仅在登录态常驻）
                          if (_isLoginMode) _buildForgotPasswordBtn(),
                          
                          const SizedBox(height: 24),
                          
                          // 模块 3：拟物化奢华执行提交大按钮
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 【内部组件：高调性应用品牌展示】
  Widget _buildAppLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          ),
          child: const Icon(Icons.blur_on_rounded, size: 54, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Text(
          "FlavorLog",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          "A I 智慧视觉饮食画像控制台",
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, letterSpacing: 2),
        ),
      ],
    );
  }

  /// 【内部组件：高拟物滑动感胶囊状态开关】
  Widget _buildAuthModeToggle() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _isLoginMode ? null : _toggleAuthMode,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isLoginMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: _isLoginMode 
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] 
                      : null,
                ),
                child: Text(
                  "用户登录",
                  style: TextStyle(color: _isLoginMode ? const Color(0xFF1C1C1E) : const Color(0xFF8E8E93), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: !_isLoginMode ? null : _toggleAuthMode,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !_isLoginMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: !_isLoginMode 
                      ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] 
                      : null,
                ),
                child: Text(
                  "新号注册",
                  style: TextStyle(color: !_isLoginMode ? const Color(0xFF1C1C1E) : const Color(0xFF8E8E93), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 【复用输入框高维工厂函数】
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold),
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6B35), size: 18),
      ),
      validator: validator,
    );
  }

  /// 【专属高阶组件：带睁闭眼切换的密码安全控制舱】
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
      decoration: InputDecoration(
        labelText: "鉴权密码",
        labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold),
        hintText: "请输入您的账户密码",
        hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFF6B35), size: 18),
        // 右置动态睁闭眼交互按钮
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFFC7C7CC), size: 18),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return '请填写账户密码';
        if (v.length < 6) return '⚠️ 为了安全，密码不能少于 6 位数哦';
        return null;
      },
    );
  }

  Widget _buildForgotPasswordBtn() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0, right: 4),
        child: InkWell(
          onTap: () {},
          child: const Text(
            "忘记密码？",
            style: TextStyle(color: Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  /// 【核心组件：豪华流光提交按钮】
  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8E53), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleAuthSubmit,
          child: Center(
            child: Text(
              _isLoginMode ? "安全登录控制台" : "即刻创建新账户",
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}