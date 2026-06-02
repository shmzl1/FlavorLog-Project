// frontend/lib/pages/auth/auth_page.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  static const Color _brandColor = Color(0xFFFF6B35);
  static const Color _textColor = Color(0xFF111111);
  static const Color _subTextColor = Color(0xFF8E8E93);
  static const Color _inputBgColor = Color(0xFFF5F5F7);

  final _formKey = GlobalKey<FormState>();
  final _accountCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _accountCtrl.dispose();
    _nicknameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      Get.find<AuthController>().clearError();
    });
  }

  Future<void> _handleAuthSubmit() async {
    if (!_agreedToTerms) {
      _showSnackBar('请先阅读并同意用户协议和隐私政策');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final controller = Get.find<AuthController>();
    final bool ok;
    if (_isLoginMode) {
      ok = await controller.login(
        account: _accountCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } else {
      ok = await controller.register(
        nickname: _nicknameCtrl.text.trim(),
        email: _accountCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmPasswordCtrl.text,
      );
    }

    if (!mounted) return;
    if (ok) {
      Get.offAllNamed(AppRoutes.home);
      return;
    }

    final message = controller.errorMessage.value;
    _showSnackBar(
      message.isNotEmpty ? message : (_isLoginMode ? '登录失败，请重试' : '注册失败，请重试'),
      isError: true,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFF4757) : _textColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 34),
              _buildBrandHeader(),
              const SizedBox(height: 36),
              _buildModeTabs(),
              const SizedBox(height: 24),
              _buildAuthForm(),
              const SizedBox(height: 18),
              _buildAgreementRow(),
              const SizedBox(height: 22),
              _buildPrimaryButton(),
              const SizedBox(height: 22),
              _buildSwitchAuthText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Get.offAllNamed(AppRoutes.authGate);
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: _textColor,
          tooltip: '返回',
        ),
        TextButton(
          onPressed: _showHelpDialog,
          child: const Text(
            '帮助',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: _brandColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: _brandColor,
            size: 38,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '知味志 FlavorLog',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textColor,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isLoginMode ? '登录后，记录你的每日饮食' : '用 AI 记录饮食，管理健康生活',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _subTextColor,
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildModeTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildModeTab('登录', _isLoginMode),
          _buildModeTab('注册', !_isLoginMode),
        ],
      ),
    );
  }

  Widget _buildModeTab(String text, bool active) {
    return Expanded(
      child: InkWell(
        onTap: active ? null : _toggleAuthMode,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: active ? _textColor : _subTextColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLoginMode) ...[
            _buildInputField(
              controller: _nicknameCtrl,
              hintText: '昵称',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty) ? '昵称不能为空' : null,
            ),
            const SizedBox(height: 14),
          ],
          _buildInputField(
            controller: _accountCtrl,
            hintText: _isLoginMode ? '账号 / 邮箱 / 手机号' : '邮箱或手机号',
            icon: Icons.alternate_email_rounded,
            keyboardType: _isLoginMode ? TextInputType.text : TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateAccount,
          ),
          const SizedBox(height: 14),
          _buildPasswordField(),
          if (!_isLoginMode) ...[
            const SizedBox(height: 14),
            _buildConfirmPasswordField(),
          ],
        ],
      ),
    );
  }

  String? _validateAccount(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return _isLoginMode ? '账号不能为空' : '邮箱或手机号不能为空';
    }
    if (_isLoginMode) return null;
    final isEmail = GetUtils.isEmail(input);
    final isPhone = AuthController.isChinesePhone(input);
    if (!isEmail && !isPhone) {
      return '请输入合法邮箱或 11 位手机号';
    }
    return null;
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: _textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(hintText: hintText, icon: icon),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscurePassword,
      textInputAction: _isLoginMode ? TextInputAction.done : TextInputAction.next,
      style: const TextStyle(
        color: _textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        hintText: '密码',
        icon: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: _subTextColor,
            size: 20,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '密码不能为空';
        if (value.length < 6) return '密码长度至少 6 位';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordCtrl,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: _textColor,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: _inputDecoration(
        hintText: '确认密码',
        icon: Icons.lock_clock_outlined,
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: _subTextColor,
            size: 20,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '请再次输入密码';
        if (value != _passwordCtrl.text) return '两次密码不一致';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _subTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: _inputBgColor,
      prefixIcon: Icon(icon, color: _subTextColor, size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _brandColor, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF4757), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF4757), width: 1.2),
      ),
    );
  }

  Widget _buildAgreementRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Checkbox(
            value: _agreedToTerms,
            activeColor: _brandColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: _subTextColor,
                  fontSize: 12,
                  height: 1.65,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(text: '我已阅读并同意'),
                  _agreementLink('《用户协议》', _showUserAgreementDialog),
                  _agreementLink('《隐私政策》', _showPrivacyPolicyDialog),
                  _agreementLink('《个人信息保护规则》', _showPersonalInfoProtectionDialog),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  TextSpan _agreementLink(String text, VoidCallback onTap) {
    return TextSpan(
      text: text,
      style: const TextStyle(
        color: _brandColor,
        fontWeight: FontWeight.w800,
      ),
      recognizer: TapGestureRecognizer()..onTap = onTap,
    );
  }

  Widget _buildPrimaryButton() {
    final controller = Get.find<AuthController>();
    return Obx(() {
      final loading = controller.isLoading.value;
      return SizedBox(
        height: 56,
        child: FilledButton(
          onPressed: loading ? null : _handleAuthSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: _brandColor,
            disabledBackgroundColor: _brandColor.withOpacity(0.55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isLoginMode ? '登录' : '注册',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildSwitchAuthText() {
    return Center(
      child: TextButton(
        onPressed: _toggleAuthMode,
        child: Text(
          _isLoginMode ? '没有账号？立即注册' : '已有账号？去登录',
          style: const TextStyle(
            color: _brandColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    _showAgreementDialog(
      '帮助',
      '1. 支持邮箱或手机号登录。\n\n'
          '2. 忘记密码请联系项目维护人员。\n\n'
          '3. 若网络请求失败，请确认后端服务已启动。\n\n'
          '4. 如果使用 USB 真机调试，请确认已经执行 adb reverse tcp:8000 tcp:8000。',
    );
  }

  void _showUserAgreementDialog() {
    _showAgreementDialog(
      '用户协议',
      '欢迎使用 FlavorLog。本应用是一个饮食记录与健康管理辅助工具，主要用于帮助用户记录饮食、管理冰箱食材、查看健康报告和参与社区交流。\n\n'
          '用户在使用本应用时，应保证注册信息真实、合法、有效，不得冒用他人身份，不得发布违法、侵权、攻击性或与饮食健康无关的内容。\n\n'
          '本应用提供的饮食分析、健康建议、食材识别和周报内容，仅作为日常健康管理参考，不构成医学诊断、治疗建议或专业营养处方。如用户存在疾病、过敏、特殊饮食限制或其他健康问题，应咨询医生、营养师等专业人士。\n\n'
          '用户应妥善保管账号信息。因用户自行泄露账号、密码或设备信息导致的数据风险，由用户自行承担。\n\n'
          '项目团队会持续优化功能，但不保证所有功能在任何网络环境、设备环境下均完全无误。因网络中断、服务维护、第三方接口异常等原因导致的功能不可用，项目团队会尽力修复。\n\n'
          '用户继续使用本应用，即表示已阅读并同意本协议内容。',
    );
  }

  void _showPrivacyPolicyDialog() {
    _showAgreementDialog(
      '隐私政策',
      'FlavorLog 重视用户隐私保护。本应用可能会收集用户在使用过程中主动填写或上传的信息，包括账号信息、昵称、饮食记录、食材信息、餐后反馈、健康目标、社区发布内容等。\n\n'
          '本应用收集上述信息的目的，是为了实现登录注册、饮食记录、健康报告、赛博冰箱、社区互动等功能，并为用户提供更准确的统计和展示。\n\n'
          '本应用不会主动向无关第三方出售、出租或公开用户个人信息。因课程项目演示、系统调试或功能测试需要查看数据时，应尽量避免泄露用户隐私。\n\n'
          '用户上传的图片、视频或文本内容，可能会用于食材识别、饮食分析或社区展示。用户应避免上传包含敏感身份信息、他人隐私或违法内容的资料。\n\n'
          '本应用会尽力采取合理措施保护用户数据安全，但由于网络环境、设备环境、第三方服务等因素影响，无法保证绝对安全。\n\n'
          '用户可以停止使用本应用，或联系项目维护人员删除、修改相关测试数据。',
    );
  }

  void _showPersonalInfoProtectionDialog() {
    _showAgreementDialog(
      '个人信息保护规则',
      '为保障用户个人信息安全，FlavorLog 将遵循必要、合理、最小化原则处理用户信息。\n\n'
          '本应用可能处理的信息包括：账号信息、登录状态、饮食记录、食材记录、餐后反馈、健康目标、社区互动内容以及用户主动上传的图片、视频等数据。\n\n'
          '本应用仅在实现功能所必需的范围内使用用户信息。例如：饮食记录用于生成首页营养看板和智能周报；餐后反馈用于生成红黑榜；冰箱食材信息用于库存管理和食材识别；社区内容用于帖子展示和互动。\n\n'
          '用户应避免在昵称、备注、社区发帖、评论等位置填写身份证号、家庭住址、银行卡号、精确定位等敏感信息。\n\n'
          '项目团队在开发和演示过程中，应避免将用户个人信息用于与课程项目无关的用途。\n\n'
          '如后续项目继续完善，应逐步增加用户信息查询、修改、删除和注销能力。',
    );
  }

  void _showAgreementDialog(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxHeight = MediaQuery.of(dialogContext).size.height * 0.62;
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              color: _textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(
                  color: Color(0xFF3A3A3C),
                  fontSize: 14,
                  height: 1.75,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                '我知道了',
                style: TextStyle(
                  color: _brandColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
