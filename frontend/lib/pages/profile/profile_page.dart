// frontend/lib/pages/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../app/routes/app_routes.dart';

/// 【类说明：FlavorLog 个人中心页 (现代轻奢极简版)】
/// 设计亮点：
/// 1. 采用 CustomScrollView + SliverAppBar 打造沉浸式的滑动体验。
/// 2. 彻底移除了容易引发图层撞车重叠的“我的主页”固定文本，使头部高光更加通透、极简。
/// 3. 设置列表采用 iOS 风格的 Grouped List（分组圆角列表），告别粗糙的分割线。
class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 统一的全局微灰背景
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 个人健康数据成就看板
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  
                  // 2. 偏好与设置区域
                  const Text(
                    "专属设置",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsGroup(),
                  
                  const SizedBox(height: 32),
                  
                  // 3. 危险操作区 (退出登录)
                  _buildLogoutButton(),
                  
                  const SizedBox(height: 60), // 底部防遮挡留白
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 【组件：沉浸式可折叠头部 (已彻底切除重叠文字)】
  /// 作用：纯净展示头像、昵称，彻底杜绝文字图层冲突。
  Widget _buildSliverAppBar(BuildContext context) {
    // 获取手机系统的顶部安全状态栏高度，防止刘海屏遮挡
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return SliverAppBar(
      expandedHeight: 240.0, // 适度调优总高度，让内容在无标题干扰下达到黄金视觉中轴线
      floating: false,
      pinned: true, // 折叠后变成常驻干净导航栏
      backgroundColor: const Color(0xFFF8F9FA),
      elevation: 0,
      
      // 【关键修复点】：已遵照指示彻底移除 title 文本，确保 0 重叠冲突风险
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin, // 滚动时背景固定收缩
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 采用绝对居中排布
          children: [
            // 预留出顶部【状态栏 + 导航栏】的总高度
            SizedBox(height: statusBarHeight + kToolbarHeight),
            
            // 呼吸感高光头像组件
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFFCC00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3), 
                    blurRadius: 16, 
                    offset: const Offset(0, 8)
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFFFAFAFA),
                  child: Icon(Icons.face_retouching_natural_rounded, size: 48, color: Color(0xFFFF6B35)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            
            // 用户昵称
            const Text(
              "美食探索家",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1C1C1E), 
                letterSpacing: 0.5
              ),
            ),
            const SizedBox(height: 6),
            
            // 用户等级勋章标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F0CB), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: const Text(
                "LV.3 减脂达人", 
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF558B2F))
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 【组件：Bento 风格成就数据栏】
  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("打卡天数", "14", "天", Icons.calendar_month_rounded, const Color(0xFF5AC8FA))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("记录饮食", "32", "餐", Icons.restaurant_rounded, const Color(0xFFFF8E53))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("获赞数量", "128", "次", Icons.favorite_rounded, const Color(0xFFFF4757))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }

  /// 【组件：果味分组设置列表】
  Widget _buildSettingsGroup() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            "饮食与过敏原偏好", 
            Icons.no_meals_rounded, 
            const Color(0xFF20BF6B), 
            true, 
            _showComingSoonSnackbar, // 挂载提示弹窗
          ),
          _buildDivider(),
          _buildSettingsTile(
            "我的赛博冰箱", 
            Icons.kitchen_rounded, 
            const Color(0xFF4CD964), 
            true, 
            () => Get.toNamed(AppRoutes.CYBER_FRIDGE), 
          ),
          _buildDivider(),
          _buildSettingsTile(
            "健康数据报告", 
            Icons.monitor_heart_rounded, 
            const Color(0xFFFF6B35), 
            true, 
            () => Get.toNamed(AppRoutes.HEALTH_REPORT), 
          ),
          _buildDivider(),
          _buildSettingsTile(
            "账号与安全", 
            Icons.shield_rounded, 
            const Color(0xFF5AC8FA), 
            true, 
            _showComingSoonSnackbar, 
          ),
          _buildDivider(),
          _buildSettingsTile(
            "关于 FlavorLog", 
            Icons.info_outline_rounded, 
            const Color(0xFF8E8E93), 
            false, 
            _showComingSoonSnackbar, 
          ),
        ],
      ),
    );
  }

  /// 封装一个统一的、高颜值的未开放功能提示浮窗
  void _showComingSoonSnackbar() {
    Get.snackbar(
      '功能施工中 🚧',
      '攻城狮正在没日没夜地敲键盘，该功能即将上线，敬请期待！',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: const Icon(Icons.engineering_rounded, color: Color(0xFFFFCC00)),
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, Color iconBgColor, bool showArrow, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBgColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconBgColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
            ),
            if (showArrow) const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 64, right: 20),
      child: Divider(height: 1, thickness: 0.5, color: Color(0xFFF2F2F7)),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () {
        Get.snackbar(
          '安全下线',
          '账号已成功退出，期待你的下次探索！',
          backgroundColor: const Color(0xFFFF4757),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          borderRadius: 16,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            "退出登录",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFFF4757)),
          ),
        ),
      ),
    );
  }
}