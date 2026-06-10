// frontend/lib/pages/cyber_fridge/cyber_fridge_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../controllers/fridge_controller.dart';
import '../../models/fridge_item_model.dart';
import '../../utils/shelf_life_utils.dart';
import 'fridge_video_entry_page.dart';

/// 【类说明：赛博冰箱 (Cyber Fridge) 现代高颜值全交互版】
/// 核心视觉设计：
/// 1. 采用清爽的“马卡龙绿”为主色调，呼应“新鲜、健康、生命力”的食材管理理念。
/// 2. 顶部大看板展示“保质期预警”，下方采用双列瀑布流 / Bento Grid 展示具体食材。
/// 3. 【新升级】：激活了真实的分类 Tab 联动过滤引擎，告别花瓶 UI。
class CyberFridgePage extends GetView<FridgeController> {
  const CyberFridgePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // 底部悬浮的炫酷添加按钮（已激活点击交互）
      floatingActionButton: _buildAddButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // 核心内容区由独立的过滤引擎组件接管
      body: const _FridgeView(),
    );
  }

  /// 【组件：底部悬浮炫彩添加按钮】
  Widget _buildAddButton(BuildContext context) {
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
          onTap: () async {
            final controller = Get.find<FridgeController>();
            final refreshed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const FridgeVideoEntryPage(),
              ),
            );
            if (refreshed == true) controller.loadItems();
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

/// 【高级独立组件：带真实过滤引擎的冰箱食材视图】
/// 修复说明：
/// 内部构建了带标签的 Mock 数据源，通过 _selectedCategory 状态变量，
/// 实时驱动下方的 SliverGrid 进行智能洗牌过滤。
class _FridgeView extends StatefulWidget {
  const _FridgeView({Key? key}) : super(key: key);

  @override
  State<_FridgeView> createState() => _FridgeViewState();
}

class _FridgeViewState extends State<_FridgeView> {
  String _selectedCategory = '全部';

  // ── 辅助：根据分类返回 emoji 图标 ──────────────────────────
  static String _icon(String? cat) {
    if (cat == null) return '🥡';
    if (cat.contains('蔬菜') || cat.contains('菜')) return '🥬';
    if (cat.contains('肉')) return '🥩';
    if (cat.contains('蛋') || cat.contains('奶')) return '🥚';
    if (cat.contains('水果') || cat.contains('果')) return '🍎';
    if (cat.contains('海鲜') || cat.contains('鱼')) return '🐟';
    if (cat.contains('饮料') || cat.contains('汤')) return '🥤';
    return '🥡';
  }

  // ── FridgeItemModel → 卡片所需 Map ─────────────────────────
  Map<String, dynamic> _toCard(FridgeItemModel item) {
    int days;
    String status = 'safe';
    if (item.expireDate != null) {
      final expire = DateTime.tryParse(item.expireDate!);
      if (expire != null) {
        days = expire.difference(DateTime.now()).inDays;
        if (days < 0) {
          days = 0;
          status = 'danger';
        } else if (days < 3) {
          status = 'danger';
        } else if (days < 7) {
          status = 'warning';
        }
      } else {
        days = ShelfLifeUtils.estimateDays(name: item.name, category: item.category);
      }
    } else {
      // 未填写保质期时，按食材名 / 分类智能估算大概天数
      days = ShelfLifeUtils.estimateDays(name: item.name, category: item.category);
      if (days < 3) {
        status = 'danger';
      } else if (days < 7) {
        status = 'warning';
      }
    }
    final cat = item.category ?? '其他';
    return {
      'id': item.id,
      'name': item.name,
      'icon': _icon(cat),
      'qty': '${item.quantity.toInt()}${item.unit ?? '个'}',
      'days': days,
      'status': status,
      'category': cat,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FridgeController>(
      builder: (ctrl) {
        final allCards = ctrl.items.map(_toCard).toList();
        // 动态分类池（保留固定顺序）
        const fixedOrder = ['蔬菜', '肉类', '蛋奶', '水果', '海鲜', '饮料'];
        final catSet = allCards.map((c) => c['category'] as String).toSet();
        final dynamicCats = [
          ...fixedOrder.where(catSet.contains),
          ...catSet.where((c) => !fixedOrder.contains(c)),
        ];
        final categories = ['全部', ...dynamicCats];

        // 重置不合法的选中项
        if (_selectedCategory != '全部' && !catSet.contains(_selectedCategory)) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCategory = '全部');
          });
        }

        final filteredItems = _selectedCategory == '全部'
            ? allCards
            : allCards.where((c) => c['category'] == _selectedCategory).toList();

        if (ctrl.isLoading.value && allCards.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF20BF6B)),
            ),
          );
        }

        final expiringCount = allCards.where((c) => c['status'] != 'safe').length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: _buildOverviewBoard(allCards.length, expiringCount),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _buildCategoryChips(categories),
              ),
            ),
            if (ctrl.errorMessage.value.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 48, color: Color(0xFF8E8E93)),
                        const SizedBox(height: 12),
                        Text(ctrl.errorMessage.value,
                            style: const TextStyle(color: Color(0xFF8E8E93))),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: ctrl.loadItems,
                          child: const Text('重新加载'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (filteredItems.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.kitchen_rounded,
                            size: 60,
                            color: const Color(0xFF8E8E93).withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          allCards.isEmpty
                              ? '冰箱是空的，点下方按钮录入食材吧！'
                              : '该分类暂无食材',
                          style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                sliver: _buildFridgeGrid(filteredItems),
              ),
          ],
        );
      },
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
  Widget _buildOverviewBoard(int totalCount, int expiringCount) {
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
                  child: Text(
                    expiringCount > 0 ? "⚠️ $expiringCount 项临期" : "✅ 全部新鲜",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "新鲜度健康",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  "共收纳 $totalCount 种食材",
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ],
            ),
          ),
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

  /// 【组件：支持点击交互的分类标签 (Apple Health 风格)】
  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = categories[index] == _selectedCategory;
          return GestureDetector(
            onTap: () {
              // 【交互修复】：点击即时重塑 _selectedCategory 状态，触发网格刷新
              setState(() {
                _selectedCategory = categories[index];
              });
            },
            child: Container(
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
            ),
          );
        },
      ),
    );
  }

  /// 【组件：双列网格食材卡片 (接收过滤后的动态数据)】
  Widget _buildFridgeGrid(List<Map<String, dynamic>> items) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        mainAxisSpacing: 16, 
        crossAxisSpacing: 16, 
        childAspectRatio: 0.82, 
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return _buildItemCard(item);
        },
        childCount: items.length,
      ),
    );
  }

  /// 【复杂组件：单个食材数据卡片】
  Widget _buildItemCard(Map<String, dynamic> item) {
    Color accentColor = const Color(0xFF20BF6B); 
    if (item['status'] == 'warning') accentColor = const Color(0xFFFFCC00); 
    if (item['status'] == 'danger') accentColor = const Color(0xFFFF4757); 

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
          Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 8),
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
}