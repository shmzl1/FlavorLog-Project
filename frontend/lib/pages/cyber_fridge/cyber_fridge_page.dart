// frontend/lib/pages/cyber_fridge/cyber_fridge_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../controllers/fridge_controller.dart';

/// 【类说明：赛博冰箱 (Cyber Fridge) 现代高颜值版】
/// 核心视觉设计：
/// 1. 采用清爽的“马卡龙绿”为主色调，呼应“新鲜、健康、生命力”的食材管理理念。
/// 2. 顶部大看板展示“保质期预警”，下方采用双列瀑布流 / Bento Grid 展示具体食材。
/// 3. 每个食材卡片带有拟物化的进度条，直观反映新鲜度。
class CyberFridgePage extends GetView<FridgeController> {
  const CyberFridgePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // 底部悬浮的炫酷添加按钮
      floatingActionButton: _buildAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. 沉浸式毛玻璃导航栏
          _buildSliverAppBar(context),
          
          // 2. 核心看板区 (保质期预警 & 食材总览)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _buildOverviewBoard(),
            ),
          ),
          
          // 3. 分类标签栏
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: _buildCategoryChips(),
            ),
          ),
          
          // 4. 食材 Bento 网格区
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), // 底部留白防止被 FAB 遮挡
            sliver: _buildFridgeGrid(),
          ),
        ],
      ),
    );
  }

  /// 【组件：果味沉浸式头部】
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF8F9FA).withOpacity(0.85),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
        onPressed: () => Get.back(), 
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: const FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(left: 60, bottom: 16),
            title: Text(
              "赛博冰箱",
              style: TextStyle(
                color: Color(0xFF1C1C1E),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 【组件：冰箱状态总览大看板】
  /// 作用：展示快过期的食物和食材总数，采用与首页呼应的渐变色。
  Widget _buildOverviewBoard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF20BF6B), Color(0xFF4CD964)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20BF6B).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "⚠️ 2 项临期",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "新鲜度健康",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  "共收纳 15 种食材",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          // 装饰性微缩图标
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 40),
          )
        ],
      ),
    );
  }

  /// 【组件：横向滚动分类标签 (Apple Health 风格)】
  Widget _buildCategoryChips() {
    final List<String> categories = ["全部", "🥬 蔬菜", "🥩 肉类", "🥚 蛋奶", "🍎 水果"];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0; // 默认选中第一个
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected 
                  ? [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] 
                  : [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              categories[index],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 【组件：双列网格食材卡片】
  Widget _buildFridgeGrid() {
    // 这里使用模拟数据构建极致的 UI 展示，后期可替换为 controller.items
    final List<Map<String, dynamic>> mockItems = [
      {'name': '西蓝花', 'icon': '🥦', 'days': 2, 'qty': '500g', 'status': 'warning'},
      {'name': '三文鱼', 'icon': '🍣', 'days': 1, 'qty': '200g', 'status': 'danger'},
      {'name': '鸡蛋', 'icon': '🥚', 'days': 12, 'qty': '10个', 'status': 'safe'},
      {'name': '全脂牛奶', 'icon': '🥛', 'days': 5, 'qty': '1L', 'status': 'safe'},
      {'name': '牛油果', 'icon': '🥑', 'days': 3, 'qty': '3个', 'status': 'warning'},
      {'name': '鸡胸肉', 'icon': '🥩', 'days': 30, 'qty': '1kg', 'status': 'safe'},
    ];

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 双列排版
        mainAxisSpacing: 16, // 纵向间距
        crossAxisSpacing: 16, // 横向间距
        childAspectRatio: 0.82, // 卡片长宽比，打造微距立体的效果
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = mockItems[index];
          return _buildItemCard(item);
        },
        childCount: mockItems.length,
      ),
    );
  }

  /// 【复杂组件：单个食材数据卡片】
  /// 自动根据保质期天数计算进度条和颜色（红、黄、绿）
  Widget _buildItemCard(Map<String, dynamic> item) {
    // 根据状态配置颜色
    Color accentColor = const Color(0xFF20BF6B); // 默认绿色
    if (item['status'] == 'warning') accentColor = const Color(0xFFFFCC00); // 临近黄色
    if (item['status'] == 'danger') accentColor = const Color(0xFFFF4757); // 过期红色

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：Emoji图标与余量
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text(item['icon'], style: const TextStyle(fontSize: 22)),
              ),
              Text(item['qty'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
            ],
          ),
          const Spacer(),
          // 食材名称
          Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 8),
          // 底部：保质期进度与倒计时
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "剩 ${item['days']} 天",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 新鲜度进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item['days'] > 14 ? 1.0 : (item['days'] / 14.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF2F2F7),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          )
        ],
      ),
    );
  }

  /// 【组件：底部悬浮炫彩添加按钮】
  Widget _buildAddButton() {
    return Container(
      height: 60,
      width: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            // 后期可对接扫码/录入弹窗
            // Get.bottomSheet(...)
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_rounded, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text("录入新食材", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}