import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../app/routes/app_routes.dart';

/// 【类说明：FlavorLog 智慧健康饮食首页 (Bento + Glassmorphism 终极进化版)】
class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // 更柔和的底色，衬托卡片阴影
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. 沉浸式动态头部
          _buildSliverAppBar(context),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // 2. 营养仪表盘 (Apple Fitness 风格环形/条形)
                  _buildBentoNutritionDashboard(),
                  const SizedBox(height: 24),
                  // 3. AI 建议卡片 (玻璃态质感)
                  _buildGlassAiTipCard(),
                  const SizedBox(height: 24),
                  // 4. 功能网格 (Bento Grid)
                  _buildBentoFeatureGrid(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final int hour = DateTime.now().hour;
    String greeting = "你好";
    if (hour < 11) { greeting = "早安"; }
    else if (hour < 14) { greeting = "午安"; }
    else if (hour < 19) { greeting = "下午好"; }
    else { greeting = "晚安"; }

    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFFF2F2F7),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
            // 控制滚动缩小文字逻辑
            final isCollapsed = constraints.biggest.height <= kToolbarHeight + MediaQuery.of(context).padding.top + 10;
            return isCollapsed 
              ? Text(
                  greeting, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1E))
                )
              : const SizedBox.shrink();
          },
        ),
        background: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20, 
            right: 20
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    controller.username.value.isNotEmpty ? controller.username.value : "美食探索家",
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E), letterSpacing: -0.5),
                  )),
                ],
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.profile),
                child: Hero(
                  tag: 'avatar_hero',
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFCC00), Color(0xFFFF6B35)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoNutritionDashboard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
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
                "今日看板",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.HEALTH_REPORT),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("报告 ⚡", style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() => Row(
            children: [
              // 粗环形进度带
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: controller.calorieProgress.value,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFF2F2F7),
                      strokeCap: StrokeCap.round,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.remainingCaloriesText,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
                      ),
                      const Text(
                        "千卡余",
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildMacronutrientBar("碳水", controller.carbText, controller.carbProgress.value, const Color(0xFF4CD964)),
                    const SizedBox(height: 16),
                    _buildMacronutrientBar("蛋白", controller.proteinText, controller.proteinProgress.value, const Color(0xFF5AC8FA)),
                    const SizedBox(height: 16),
                    _buildMacronutrientBar("脂肪", controller.fatText, controller.fatProgress.value, const Color(0xFFFFCC00)),
                  ],
                ),
              )
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildMacronutrientBar(String label, String valueText, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1E))),
            Text(valueText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF2F2F7),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassAiTipCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // 背景光晕
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6B35).withOpacity(0.1)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFF6B35), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("AI 饮食密语", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 6),
                      Obx(() => Text(
                        controller.aiTip.value,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.5, fontWeight: FontWeight.w500),
                      )),
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

  Widget _buildBentoFeatureGrid() {
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          // 左侧大卡片：拍照录入
          Expanded(
            flex: 6,
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.FOOD_RECORD),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF8A5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_rounded, color: Colors.white, size: 32),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("智能录入", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        SizedBox(height: 4),
                        Text("一键识别菜品", style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 右侧小卡片
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _buildSmallBentoCard(
                  title: "赛博冰箱",
                  subtitle: "食材追踪",
                  icon: Icons.kitchen_rounded,
                  bgColor: const Color(0xFF20BF6B),
                  onTap: () => Get.toNamed(AppRoutes.CYBER_FRIDGE),
                ),
                const SizedBox(height: 16),
                _buildSmallBentoCard(
                  title: "灵感社区",
                  subtitle: "低卡食谱",
                  icon: Icons.explore_rounded,
                  bgColor: const Color(0xFF5AC8FA),
                  onTap: () => Get.toNamed(AppRoutes.COMMUNITY),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSmallBentoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
