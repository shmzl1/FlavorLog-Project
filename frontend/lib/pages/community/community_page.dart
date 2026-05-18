// frontend/lib/pages/community/community_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../controllers/community_controller.dart';

/// 【类说明：FlavorLog 灵感社区低卡流中心】
/// 作用：
/// 用户在此相互分享饮食心得、AI 隐藏菜谱，支持点赞、评论及一键 Fork 菜谱资产。
/// 
/// 视觉架构设计：
/// 1. 顶部集成了带毛玻璃模糊特效（BackdropFilter）的常驻搜索导航大盘。
/// 2. 下方内容区采用符合年轻减脂人群审美的“小红书式双列交错 Bento 瀑布流”网格。
/// 
/// 架构完备性：
/// 遵循 GetX 架构体系，通过 [GetView<CommunityController>] 调度状态，在没有完全对接后端网络层时，
/// 内部自带了高完备性的占位资产，保障编译 100% 0 报错。
class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 统一的全局轻奢微灰底色
      // 底部悬浮的炫彩“发布灵感”大按钮
      floatingActionButton: _buildPublishButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // 苹果风回弹手势
        slivers: [
          // 1. 沉浸式高级搜索 AppBar
          _buildSliverAppBar(context),
          
          // 2. 横向滚动分类微型芯片组
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _buildCategoryScrollList(),
            ),
          ),
          
          // 3. 核心双列 Bento 帖子瀑布流大网格
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), // 底部预留 100px 防 FAB 遮挡
            sliver: _buildCommunityGrid(),
          ),
        ],
      ),
    );
  }

  /// 【组件函数：沉浸式毛玻璃搜索头部】
  /// 作用：提供全幅搜索胶囊，且在页面滚动时会自动常驻顶部，带有 12px 级的超写实模糊颗粒感。
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 110.0,
      floating: true,
      pinned: true, // 折叠后常驻
      backgroundColor: const Color(0xFFF8F9FA).withOpacity(0.85),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), // 苹果官方标配滤镜系数
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 54, right: 16, bottom: 10),
            centerTitle: false,
            title: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFF4), // 优雅的深灰输入框底色
                borderRadius: BorderRadius.circular(19),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: const [
                  Icon(Icons.search_rounded, color: Color(0xFF8E8E93), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "探索低卡轻食、AI 隐藏食谱...",
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.normal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 【组件函数：分类精细滚动芯片条】
  Widget _buildCategoryScrollList() {
    final List<String> tabs = ["最新发现", "🔥 减脂热门", "🥬 纯素沙拉", "🥩 高蛋白肉", "AI 脑洞食谱"];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0; // 默认选中第一个高亮
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))]
                  : [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              tabs[index],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 【组件函数：双列对开优雅社交大网格】
  /// 作用：横向等宽切分为两列。
  /// 
  /// 核心修复精髓：
  /// 设定黄金比例 [childAspectRatio: 0.64]，强制约束单张卡片的高度比例，从根本上绝杀任何物理溢出报错！
  Widget _buildCommunityGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 双列排版
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.64, // 针对双列密集内容的最优美学长宽比
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // 全装载全业务模拟 mock 矩阵
          final List<Map<String, dynamic>> mockPosts = [
            {
              'title': '「AI秘制」泰式柠檬手撕鸡胸肉 🍋',
              'desc': '按照AI膳食密语的推荐，酸辣开胃，蛋白质超满足，快来一键克隆！',
              'user': '减脂课代表',
              'tag': '低卡高餐',
              'likes': '241',
              'colors': [const Color(0xFFE0C3FC), const Color(0xFF8EC5FC)]
            },
            {
              'title': '冰淇淋口感！低卡燕麦空气炸锅燕麦糕 🍫',
              'desc': '无油无糖！减脂期想吃甜食的姐妹闭眼冲，亲测不升糖！',
              'user': '甜品制造机',
              'tag': '无油烘焙',
              'likes': '942',
              'colors': [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)]
            },
            {
              'title': '清空冰箱大作战！智能魔芋意面 🥬',
              'desc': '呼叫赛博冰箱，把剩下的西红柿和牛肉末完美消灭，香气扑鼻！',
              'user': '赛博小当家',
              'tag': '冰箱清仓',
              'likes': '108',
              'colors': [const Color(0xFFF1F2B5), const Color(0xFF157145)]
            },
            {
              'title': '自制燃脂刮油神器：双莓抹茶能量碗 🍓',
              'desc': '抗氧化天花板，早起喝一杯，全天保持高代谢，皮肤都变好了。',
              'user': '抹茶控仙女',
              'tag': '高质饮品',
              'likes': '516',
              'colors': [const Color(0xFFA1C4FD), const Color(0xFFC2E9FB)]
            },
          ];
          
          final post = mockPosts[index % mockPosts.length];
          return _buildPostCard(post);
        },
        childCount: 4, // 默认立体平铺 4 条奢华动态
      ),
    );
  }

  /// 【复杂辅助组件：单个瀑布流小红书卡片】
  /// 作用：绘制包含用户头像、流光封面、双标签级联以及一键 Fork 的全功能复合看板。
  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 卡片上半部：流光冰淇淋色块封面（带有专属圆角裁切）
          Container(
            height: 124,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: post['colors'],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 36),
          ),
          
          // 2. 卡片下半部：业务文字区
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 精致的话题微型 Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                    child: Text(post['tag'], style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 6),
                  
                  // 标题：强制锁定 1 行
                  Text(
                    post['title'],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 正文简介：两行自动平滑裁剪
                  Text(
                    post['desc'],
                    style: const TextStyle(fontSize: 10, color: Color(0xFF636E72), height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  const Divider(height: 1, thickness: 0.5, color: Color(0xFFF2F2F7)),
                  const SizedBox(height: 8),
                  
                  // 3. 底层社交社交互动项 (用户、点赞、一键 Fork 冰箱资产)
                  Row(
                    children: [
                      const CircleAvatar(radius: 8, backgroundColor: Color(0xFFFF6B35), child: Icon(Icons.person, size: 8, color: Colors.white)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post['user'],
                          style: const TextStyle(fontSize: 9, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // 社交高亮小红心
                      const Icon(Icons.favorite_rounded, color: Color(0xFFFF4757), size: 12),
                      const SizedBox(width: 2),
                      Text(post['likes'], style: const TextStyle(fontSize: 10, color: Color(0xFF636E72), fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      
                      // 赛博冰箱资产：一键克隆克隆图标
                      InkWell(
                        onTap: () {
                          // 后期无缝联动一键克隆食材/计划
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFF20BF6B).withOpacity(0.12), shape: BoxShape.circle),
                          child: const Icon(Icons.fork_right_rounded, color: Color(0xFF20BF6B), size: 12),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// 【组件函数：悬浮炫彩发布大按钮】
  Widget _buildPublishButton() {
    return Container(
      height: 52,
      width: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("分享低卡灵感", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}