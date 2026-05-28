// frontend/lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../app/routes/app_routes.dart';

/// 【类说明：FlavorLog 智慧健康饮食首页】
/// 作用：
/// 本类作为整个 App 的“门面”，承载了用户每天打开应用时的第一视觉。
/// 
/// 设计语言：
/// 1. 采用 Apple Health 风格的微距卡片（Bento Grid），模块化展示核心业务。
/// 2. 融入了流光渐变（Gradients）与呼吸感阴影（Soft Drop Shadows），彻底告别扁平死板。
/// 3. 顶部的智能时间问候能根据当前时间切换“早安/午安/晚安”，极大提升用户的情感共鸣。
/// 
/// 架构体系：
/// 遵循 GetX 响应式架构，通过 [GetView<HomeController>] 绑定控制器，实现 UI 与业务逻辑的完美解耦。
class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取系统的安全区域与屏幕尺寸，用于精准布局
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 现代极简微灰背景，能让白色卡片更具悬浮感
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // 引入 iOS 风格的越界回弹效果，增加滑动丝滑感
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部流光欢迎头部
            _buildHeader(statusBarHeight),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // 2. 今日营养看板（核心数字大屏）
                  _buildNutritionDashboard(),
                  
                  const SizedBox(height: 28),
                  
                  // 3. 业务功能 Bento 网格区
                  _buildFeatureGrid(),
                  
                  const SizedBox(height: 28),
                  
                  // 4. 底部的 AI 每日膳食密语
                  _buildAiTipCard(),
                  
                  const SizedBox(height: 40), // 留白，防止被系统底栏遮挡
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 【组件函数说明：智能情感化头部模块】
  /// 作用：展示用户信息、等级，并根据本地时间自动向用户问候。
  /// 
  /// 本次修改点：
  /// 在右侧悬浮头像外层包裹了 [InkWell] 组件，并指定了 [CircleBorder]，
  /// 使得点击头像时会触发丝滑的圆形水波纹动画，并安全跳转至个人中心页面（AppRoutes.profile）。
  Widget _buildHeader(double topPadding) {
    // 根据当前小时，动态获取问候语
    final int hour = DateTime.now().hour;
    String greeting = "你好";
    if (hour < 11) { greeting = "早安"; }
    else if (hour < 14) { greeting = "午安"; }
    else if (hour < 19) { greeting = "下午好"; }
    else { greeting = "晚安"; }

    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF8E8E93),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Obx(() => Text(
                (controller.username.value.isNotEmpty)
                    ? controller.username.value 
                    : "美食探索家",
                style: const TextStyle(
                  fontSize: 28,
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              )),
            ],
          ),
          
          // 【核心修复】：为悬浮头像组件穿上了“点击手势外衣”
          InkWell(
            onTap: () => Get.toNamed(AppRoutes.profile), // 点击无缝跳转个人中心
            customBorder: const CircleBorder(), // 限制水波纹特效为完美的正圆形
            child: Container(
              padding: const EdgeInsets.all(4), // 留出一点边距，让水波纹包裹更饱满
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFFF6B35),
                child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 【组件函数说明：今日营养看板（Bento 控制台）】
  /// 作用：聚合展示用户今日的卡路里、碳水、蛋白质、脂肪的摄入进度。
  Widget _buildNutritionDashboard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C1E).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "今日营养看板",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.HEALTH_REPORT),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Text("详情", style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93), size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Obx(
            () => Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: controller.calorieProgress.value,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFF2F2F7),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.remainingCaloriesText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const Text(
                          "千卡剩余",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: [
                      _buildNutrientRow(
                        "碳水",
                        controller.carbText,
                        controller.carbProgress.value,
                        const Color(0xFF4CD964),
                      ),
                      const SizedBox(height: 12),
                      _buildNutrientRow(
                        "蛋白质",
                        controller.proteinText,
                        controller.proteinProgress.value,
                        const Color(0xFF5AC8FA),
                      ),
                      const SizedBox(height: 12),
                      _buildNutrientRow(
                        "脂肪",
                        controller.fatText,
                        controller.fatProgress.value,
                        const Color(0xFFFFCC00),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 【复杂辅助函数：营养素单行条形图构建器】
  Widget _buildNutrientRow(String label, String value, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E))),
            Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: const Color(0xFFF2F2F7),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
      ],
    );
  }

  /// 【组件函数说明：现代 Bento Grid 错落功能矩阵】
  Widget _buildFeatureGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.FOOD_RECORD),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.blur_on_rounded, color: Colors.white, size: 28),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "智慧视觉记录",
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "AI 秒级识别饮食与卡路里",
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildMiniGridCard(
                title: "赛博冰箱",
                subtitle: "智能追踪食材保质期",
                icon: Icons.kitchen_rounded,
                startColor: const Color(0xFF20BF6B),
                endColor: const Color(0xFF4CD964),
                onTap: () => Get.toNamed(AppRoutes.CYBER_FRIDGE),
              ),
              const SizedBox(height: 16),
              _buildMiniGridCard(
                title: "灵感社区",
                subtitle: "探索千万种低卡菜谱",
                icon: Icons.explore_rounded,
                startColor: const Color(0xFF8E44AD),
                endColor: const Color(0xFF9B59B6),
                onTap: () => Get.toNamed(AppRoutes.COMMUNITY),
              ),
            ],
          ),
        )
      ],
    );
  }

  /// 【复杂辅助函数：半高功能卡片构建器】
  Widget _buildMiniGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 97,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: startColor.withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
          ],
        ),
      ),
    );
  }

  /// 【组件函数说明：底栏 AI 每日膳食密语卡片】
  Widget _buildAiTipCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEAA7).withOpacity(0.5), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFE1B12C), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI 膳食密语",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF7F8C8D)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.aiTip.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2C3E50),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
