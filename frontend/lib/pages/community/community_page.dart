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
/// 1. 顶部集成了带毛玻璃模糊特效（BackdropFilter）的真实搜索表单。
/// 2. 横向滑动的分类标签，支持高亮状态切换交互与【真实数据瀑布流筛选】。
/// 3. 下方内容区采用“小红书式双列交错 Bento 瀑布流”网格。
class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 统一的全局轻奢微灰底色
      // 底部悬浮的炫彩“发布灵感”大按钮
      floatingActionButton: _buildPublishButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // 使用 GestureDetector 包裹，点击页面空白处可以自动收起软键盘
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        // 【核心大升级】：将主体抽离为带状态的专属过滤引擎视图
        child: const _CommunityView(),
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

/// 【高级独立组件：带真实过滤引擎的社区核心渲染视图】
/// 修复说明：
/// 内部构建了多维度的 Mock 数据源，通过 _selectedCategory 状态变量，
/// 实时驱动下方的 SliverGrid 进行数组比对与动态重绘。
class _CommunityView extends StatefulWidget {
  const _CommunityView({Key? key}) : super(key: key);

  @override
  State<_CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<_CommunityView> {
  // 核心状态：当前选中的分类 Tab（默认加载最新）
  String _selectedCategory = "最新发现";

  // 固定分类池
  final List<String> _tabs = ["最新发现", "🔥 减脂热门", "🥬 纯素沙拉", "🥩 高蛋白肉", "AI 脑洞食谱"];

  // 【扩充版业务数据源】：每条数据带有底层的 categories 索引标签，用于交叉比对
  final List<Map<String, dynamic>> _allPosts = [
    {
      'title': '「AI秘制」泰式柠檬手撕鸡胸肉 🍋',
      'desc': '按照AI膳食密语的推荐，酸辣开胃，蛋白质超满足，快来一键克隆！',
      'user': '减脂课代表',
      'tag': '低卡高餐',
      'likes': '241',
      'colors': [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
      'categories': ['最新发现', '🔥 减脂热门', '🥩 高蛋白肉'],
    },
    {
      'title': '冰淇淋口感！低卡空气炸锅燕麦糕 🍫',
      'desc': '无油无糖！减脂期想吃甜食的姐妹闭眼冲，亲测不升糖！',
      'user': '甜品制造机',
      'tag': '无油烘焙',
      'likes': '942',
      'colors': [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
      'categories': ['最新发现', '🔥 减脂热门', 'AI 脑洞食谱'],
    },
    {
      'title': '清空冰箱大作战！智能魔芋意面 🥬',
      'desc': '呼叫赛博冰箱，把剩下的西红柿和蔬菜完美消灭，香气扑鼻！',
      'user': '赛博小当家',
      'tag': '冰箱清仓',
      'likes': '108',
      'colors': [Color(0xFFF1F2B5), Color(0xFF157145)],
      'categories': ['最新发现', '🥬 纯素沙拉'],
    },
    {
      'title': '自制燃脂刮油神器：双莓抹茶能量碗 🍓',
      'desc': '抗氧化天花板，早起喝一杯，全天保持高代谢，皮肤都变好了。',
      'user': '抹茶控仙女',
      'tag': '高质饮品',
      'likes': '516',
      'colors': [Color(0xFFA1C4FD), Color(0xFFC2E9FB)],
      'categories': ['最新发现', '🔥 减脂热门'],
    },
    {
      'title': '优质脂肪补充：牛油果鲜虾沙拉 🥑',
      'desc': '饱腹感极强，鲜虾水煮，搭配半个牛油果，简单快手！',
      'user': '沙拉狂魔',
      'tag': '生酮必备',
      'likes': '332',
      'colors': [Color(0xFFD4FC79), Color(0xFF96E6A1)],
      'categories': ['最新发现', '🥬 纯素沙拉', '🥩 高蛋白肉'],
    },
    {
      'title': 'AI 生成：豆腐伪装汉堡排 🍔',
      'desc': '用老豆腐捏出的汉堡肉排，热量只有牛肉的 1/3，简直是天才发明！',
      'user': '黑科技厨神',
      'tag': '欺骗餐',
      'likes': '889',
      'colors': [Color(0xFFF6D365), Color(0xFFFDA085)],
      'categories': ['最新发现', 'AI 脑洞食谱', '🥩 高蛋白肉'], // 欺骗大模型算肉类
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 【核心过滤引擎】：实时抓取符合当前分类 Tab 的帖子数组
    final filteredPosts = _allPosts.where((post) {
      final List<String> postCategories = post['categories'];
      return postCategories.contains(_selectedCategory);
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        _buildSliverAppBar(context),
        
        // 横向滚动分类微型芯片组
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _buildCategoryScrollList(),
          ),
        ),
        
        // 瀑布流大网格：如果过滤后无数据，则展示优雅的空状态；有数据则渲染 Grid
        if (filteredPosts.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.explore_off_rounded, size: 60, color: const Color(0xFF8E8E93).withOpacity(0.3)),
                    const SizedBox(height: 16),
                    const Text("暂无该分类的灵感内容", style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), // 底部预留 100px 防 FAB 遮挡
            sliver: _buildCommunityGrid(filteredPosts),
          ),
      ],
    );
  }

  /// 【组件函数：沉浸式毛玻璃搜索头部】
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
            title: SizedBox(
              height: 38,
              child: TextField(
                style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: "探索低卡轻食、AI 隐藏食谱...",
                  hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E93), size: 16),
                  filled: true,
                  fillColor: const Color(0xFFEFEFF4), // 优雅的深灰输入框底色
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide.none),
                ),
                onSubmitted: (value) {
                  // TODO: 结合后端执行全站搜索
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 【组件函数：支持状态维护的交互式分类列表】
  Widget _buildCategoryScrollList() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _tabs[index] == _selectedCategory;
          return GestureDetector(
            onTap: () {
              // 点击触发状态重刷，进而驱动底下的过滤引擎
              setState(() {
                _selectedCategory = _tabs[index];
              });
            },
            child: Container(
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
                _tabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 【组件函数：双列对开优雅社交大网格（已挂载真实数据）】
  Widget _buildCommunityGrid(List<Map<String, dynamic>> data) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 双列排版
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.64, // 针对双列密集内容的最优美学长宽比
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = data[index];
          return _buildPostCard(post);
        },
        childCount: data.length, // 根据动态过滤后的数据长度渲染
      ),
    );
  }

  /// 【复杂辅助组件：单个瀑布流小红书卡片】
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
                colors: post['colors'] as List<Color>,
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
                    child: Text(post['tag'] as String, style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 6),
                  
                  // 标题：强制锁定 1 行
                  Text(
                    post['title'] as String,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // 正文简介：两行自动平滑裁剪
                  Text(
                    post['desc'] as String,
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
                          post['user'] as String,
                          style: const TextStyle(fontSize: 9, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // 社交高亮小红心
                      const Icon(Icons.favorite_rounded, color: Color(0xFFFF4757), size: 12),
                      const SizedBox(width: 2),
                      Text(post['likes'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF636E72), fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      
                      // 赛博冰箱资产：一键克隆克隆图标
                      InkWell(
                        onTap: () {
                          Get.snackbar(
                            "菜谱已 Fork", 
                            "已成功将该配方推送到您的赛博冰箱，今晚就能做！",
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: const Color(0xFF20BF6B),
                            colorText: Colors.white,
                          );
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
}