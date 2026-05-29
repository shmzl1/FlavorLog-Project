// frontend/lib/pages/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/auth_controller.dart';
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
                  _buildSettingsGroup(context),
                  
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
            Obx(() => Text(
              controller.nickname.value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1C1C1E), 
                letterSpacing: 0.5
              ),
            )),
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
  Widget _buildSettingsGroup(BuildContext context) {
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
          Obx(() {
            final pTags = controller.preferenceTags;
            final aTags = controller.allergyTags;
            final List<String> displayTags = [];
            if (pTags.isNotEmpty) displayTags.add(pTags.join('、'));
            if (aTags.isNotEmpty) displayTags.add('避开：${aTags.join("、")}');
            final subText = displayTags.isEmpty ? '定制你的专属饮食画像' : displayTags.join(' ｜ ');
            
            return _buildSettingsTile(
              "饮食偏好和过敏原", 
              Icons.no_meals_rounded, 
              const Color(0xFF20BF6B), 
              true, 
              () => _showPreferencesDialog(context),
              subtitle: subText,
            );
          }),
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
          Obx(() {
            final phoneText = controller.phone.value;
            final emailText = controller.email.value;
            String safetyTip = '已绑定手机和邮箱';
            if (phoneText.isEmpty && emailText.isEmpty) {
              safetyTip = '账号安全性较低，请绑定';
            } else if (phoneText.isEmpty || emailText.isEmpty) {
              safetyTip = '建议补全绑定信息';
            }
            return _buildSettingsTile(
              "账号与安全", 
              Icons.shield_rounded, 
              const Color(0xFF5AC8FA), 
              true, 
              () => _showSecurityDialog(context),
              subtitle: safetyTip,
            );
          }),
          _buildDivider(),
          _buildSettingsTile(
            "关于 FlavorLog", 
            Icons.info_outline_rounded, 
            const Color(0xFF8E8E93), 
            false, 
            () => _showAboutDialog(context), 
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

  /// 【交互舱：关于 FlavorLog 面板】
  void _showAboutDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.only(top: 24, bottom: 40, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFCC00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.restaurant_menu_rounded, size: 36, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'FlavorLog',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Version 1.0.0 (Beta)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93)),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '你的专属 AI 智能饮食与健康管家\n用数据和算法，重新定义你的生活方式',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAboutLinkBtn('用户协议', Icons.description_outlined, _showComingSoonSnackbar),
                  _buildAboutLinkBtn('隐私政策', Icons.privacy_tip_outlined, _showComingSoonSnackbar),
                  _buildAboutLinkBtn('检查更新', Icons.system_update_alt_rounded, () {
                    Get.snackbar('已经是最新版本', 'FlavorLog 当前无需更新', snackPosition: SnackPosition.TOP, backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9), colorText: Colors.white);
                  }),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                '© 2026 FlavorLog Team. All rights reserved.',
                style: TextStyle(fontSize: 11, color: Color(0xFFC7C7CC)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutLinkBtn(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1C1C1E), size: 24),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title, 
    IconData icon, 
    Color iconBgColor, 
    bool showArrow, 
    VoidCallback onTap, {
    String? subtitle,
  }) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
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
      onTap: () async {
        Get.snackbar(
          '安全下线',
          '账号已成功退出，期待你的下次探索！',
          backgroundColor: const Color(0xFFFF4757),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          borderRadius: 16,
        );
        
        await Future.delayed(const Duration(seconds: 1));
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().logout();
          Get.offAllNamed(AppRoutes.auth);
        }
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

  /// 【交互舱：饮食偏好与过敏原高能编辑弹板】
  void _showPreferencesDialog(BuildContext context) {
    final List<String> tempPreferences = List.from(controller.preferenceTags);
    final List<String> tempAllergies = List.from(controller.allergyTags);
    
    final TextEditingController prefInputCtrl = TextEditingController();
    final TextEditingController allergyInputCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '饮食偏好和过敏原',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)),
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text('🥗', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 6),
                                Text(
                                  '饮食偏好',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (tempPreferences.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text('暂无饮食偏好标签', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tempPreferences.map((tag) {
                                  return _buildEditingTag(
                                    tag,
                                    const Color(0xFF20BF6B),
                                    () {
                                      setModalState(() {
                                        tempPreferences.remove(tag);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 12),
                            _buildMiniInputField(
                              controller: prefInputCtrl,
                              hint: '输入自定义偏好，如：抗糖',
                              activeColor: const Color(0xFF20BF6B),
                              onAdd: () {
                                final text = prefInputCtrl.text.trim();
                                if (text.isNotEmpty && !tempPreferences.contains(text)) {
                                  setModalState(() {
                                    tempPreferences.add(text);
                                  });
                                  prefInputCtrl.clear();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                '高蛋白', '低碳/生酮', '轻食减脂', '抗糖/低糖', '清淡饮食', '少盐少油'
                              ].map((rec) {
                                final selected = tempPreferences.contains(rec);
                                return _buildSelectableChip(
                                  rec,
                                  selected,
                                  const Color(0xFF20BF6B),
                                  () {
                                    setModalState(() {
                                      if (selected) {
                                        tempPreferences.remove(rec);
                                      } else {
                                        tempPreferences.add(rec);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            const Divider(height: 1, color: Color(0xFFE5E5EA)),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Text('⚠️', style: TextStyle(fontSize: 16)),
                                SizedBox(width: 6),
                                Text(
                                  '需避开的过敏原 / 食物',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (tempAllergies.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text('暂无需要避开的食物', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tempAllergies.map((tag) {
                                  return _buildEditingTag(
                                    tag,
                                    const Color(0xFFFF4757),
                                    () {
                                      setModalState(() {
                                        tempAllergies.remove(tag);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 12),
                            _buildMiniInputField(
                              controller: allergyInputCtrl,
                              hint: '输入需避开的过敏原，如：海鲜',
                              activeColor: const Color(0xFFFF4757),
                              onAdd: () {
                                final text = allergyInputCtrl.text.trim();
                                if (text.isNotEmpty && !tempAllergies.contains(text)) {
                                  setModalState(() {
                                    tempAllergies.add(text);
                                  });
                                  allergyInputCtrl.clear();
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                '花生', '海鲜', '牛奶/乳糖', '小麦/麸质', '大豆', '坚果', '鸡蛋'
                              ].map((rec) {
                                final selected = tempAllergies.contains(rec);
                                return _buildSelectableChip(
                                  rec,
                                  selected,
                                  const Color(0xFFFF4757),
                                  () {
                                    setModalState(() {
                                      if (selected) {
                                        tempAllergies.remove(rec);
                                      } else {
                                        tempAllergies.add(rec);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8A5C), Color(0xFFFF6B35)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            
                            final ok = await controller.updateProfile(
                              newDiet: tempPreferences,
                              newAllergens: tempAllergies,
                            );
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (ok) {
                                Get.snackbar(
                                  '设置已更新 🎉',
                                  '你的专属饮食偏好与过敏原配置成功同步！',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: const Color(0xFF20BF6B),
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 16,
                                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                                  duration: const Duration(seconds: 2),
                                );
                              } else {
                                Get.snackbar(
                                  '更新失败 ⚠️',
                                  '网络异常或服务器无响应，请稍后再试',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: const Color(0xFFFF4757),
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 16,
                                );
                              }
                            }
                          },
                          child: const Center(
                            child: Text(
                              '确认并保存偏好',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      prefInputCtrl.dispose();
      allergyInputCtrl.dispose();
    });
  }

  Widget _buildEditingTag(String label, Color color, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: color,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE5E5EA),
            width: 1,
          ),
          boxShadow: selected ? [] : [
            BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? color : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInputField({
    required TextEditingController controller,
    required String hint,
    required Color activeColor,
    required VoidCallback onAdd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C1E).withOpacity(0.02), 
            blurRadius: 8, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 13, fontWeight: FontWeight.normal),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
              onSubmitted: (_) => onAdd(),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_rounded, color: activeColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 【交互舱：账号与安全高能管理弹板】
  void _showSecurityDialog(BuildContext context) {
    String tempNickname = controller.nickname.value;
    String tempPhone = controller.phone.value;
    String tempEmail = controller.email.value;

    final TextEditingController nickCtrl = TextEditingController(text: tempNickname);
    final TextEditingController phoneCtrl = TextEditingController(text: tempPhone);
    final TextEditingController emailCtrl = TextEditingController(text: tempEmail);

    bool editingNick = false;
    bool editingPhone = false;
    bool editingEmail = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5EA),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xFF5AC8FA), size: 24),
                            SizedBox(width: 8),
                            Text(
                              '账号与安全管理',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)),
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildSecurityItemCard(
                              title: '用户昵称',
                              icon: Icons.person_outline_rounded,
                              displayValue: tempNickname,
                              isEditing: editingNick,
                              editingWidget: _buildInsideTextField(
                                controller: nickCtrl,
                                hint: '输入新昵称',
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    setModalState(() {
                                      tempNickname = val.trim();
                                      editingNick = false;
                                    });
                                  }
                                },
                              ),
                              onEditToggle: () {
                                setModalState(() {
                                  editingNick = !editingNick;
                                  if (editingNick) {
                                    nickCtrl.text = tempNickname;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildSecurityItemCard(
                              title: '绑定手机号',
                              icon: Icons.phone_android_rounded,
                              displayValue: tempPhone.isEmpty 
                                  ? '未绑定手机号' 
                                  : _maskSensitive(tempPhone, isEmail: false),
                              isEditing: editingPhone,
                              editingWidget: _buildInsideTextField(
                                controller: phoneCtrl,
                                hint: '输入 11 位新手机号',
                                keyboardType: TextInputType.phone,
                                onSubmitted: (val) {
                                  final clean = val.trim();
                                  if (clean.length == 11 && RegExp(r'^\d+$').hasMatch(clean)) {
                                    setModalState(() {
                                      tempPhone = clean;
                                      editingPhone = false;
                                    });
                                  } else {
                                    Get.snackbar('输入有误 ⚠️', '请输入正确的11位数字手机号',
                                        backgroundColor: const Color(0xFFFF4757), colorText: Colors.white);
                                  }
                                },
                              ),
                              onEditToggle: () {
                                setModalState(() {
                                  editingPhone = !editingPhone;
                                  if (editingPhone) {
                                    phoneCtrl.text = tempPhone;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildSecurityItemCard(
                              title: '绑定电子邮箱',
                              icon: Icons.alternate_email_rounded,
                              displayValue: tempEmail.isEmpty 
                                  ? '未绑定邮箱' 
                                  : _maskSensitive(tempEmail, isEmail: true),
                              isEditing: editingEmail,
                              editingWidget: _buildInsideTextField(
                                controller: emailCtrl,
                                hint: '输入新邮箱，如：log@163.com',
                                keyboardType: TextInputType.emailAddress,
                                onSubmitted: (val) {
                                  final clean = val.trim();
                                  if (GetUtils.isEmail(clean)) {
                                    setModalState(() {
                                      tempEmail = clean;
                                      editingEmail = false;
                                    });
                                  } else {
                                    Get.snackbar('格式错误 ⚠️', '请填写正确格式的邮箱地址',
                                        backgroundColor: const Color(0xFFFF4757), colorText: Colors.white);
                                  }
                                },
                              ),
                              onEditToggle: () {
                                setModalState(() {
                                  editingEmail = !editingEmail;
                                  if (editingEmail) {
                                    emailCtrl.text = tempEmail;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5AC8FA), Color(0xFF007AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            
                            controller.nickname.value = tempNickname;
                            controller.phone.value = tempPhone;
                            controller.email.value = tempEmail;
                            
                            if (Get.isRegistered<AuthController>()) {
                              Get.find<AuthController>().nickname.value = tempNickname;
                            }

                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (context.mounted) {
                                Navigator.pop(context);
                                
                                Get.snackbar(
                                  '信息保存成功 🛡️',
                                  '您的个人安全与资料绑定已成功更新！',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: const Color(0xFF20BF6B),
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 16,
                                );
                              }
                            });
                          },
                          child: const Center(
                            child: Text(
                              '保存并应用安全设置',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nickCtrl.dispose();
      phoneCtrl.dispose();
      emailCtrl.dispose();
    });
  }

  String _maskSensitive(String raw, {required bool isEmail}) {
    if (isEmail) {
      final parts = raw.split('@');
      if (parts.length < 2) return raw;
      final name = parts[0];
      final domain = parts[1];
      if (name.length <= 2) return '$name***@$domain';
      return '${name.substring(0, 2)}***@$domain';
    } else {
      if (raw.length < 7) return raw;
      return '${raw.substring(0, 3)}****${raw.substring(raw.length - 4)}';
    }
  }

  Widget _buildSecurityItemCard({
    required String title,
    required IconData icon,
    required String displayValue,
    required bool isEditing,
    required Widget editingWidget,
    required VoidCallback onEditToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF8E8E93), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValue,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onEditToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isEditing ? const Color(0xFFEFEFF4) : const Color(0xFF5AC8FA).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isEditing ? '取消' : '修改',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEditing ? const Color(0xFF8E8E93) : const Color(0xFF007AFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isEditing) ...[
            const SizedBox(height: 12),
            editingWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildInsideTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF20BF6B), size: 22),
            onPressed: () => onSubmitted(controller.text),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}