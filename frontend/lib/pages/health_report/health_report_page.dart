// frontend/lib/pages/health_report/health_report_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import '../../components/empty_state.dart';
import '../../components/section_card.dart';
import '../../components/stat_tile.dart';
import '../../controllers/health_report_controller.dart';
import '../../models/health_model.dart';

/// 【类说明：FlavorLog 智慧健康数据报告中心】
/// 作用：
/// 本页面作为用户饮食数据分析、AI 画像诊断和身体自主反馈的核心入口。
/// 
/// 架构体系：
/// 1. 基于 Flutter 原生 [DefaultTabController] 框架，无缝切换三大 Tab 子功能视图。
/// 2. 使用 GetX 依赖查找机制 [Get.find<HealthReportController>] 统一调度底层异步网络数据。
/// 
/// 视觉设计升级：
/// 彻底解耦原生的死板 AppBar，引入了类似 Apple Health（苹果健康）的流线型悬浮胶囊 TabBar。
class HealthReportPage extends StatelessWidget {
  const HealthReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 依赖注入：获取当前绑定的健康报告业务控制器
    final controller = Get.find<HealthReportController>();
    
    return DefaultTabController(
      length: 3, // 三大核心 Tab 子功能页
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // 全局现代微灰底色，衬托卡片悬浮感
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
            onPressed: () => Get.back(), // 安全退出页面
          ),
          title: const Text(
            '健康报告',
            style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          centerTitle: true,
          // 【高级美化】：重构底部的 TabBar，使其升级为高质感的悬浮赛博胶囊样式
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFF4), // 浅灰色胶囊底座
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                labelColor: const Color(0xFF1C1C1E),
                unselectedLabelColor: const Color(0xFF8E8E93),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.tab,
                // 胶囊选中的白色微距浮雕卡片反馈
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C1C1E).withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                tabs: const [
                  Tab(text: '智能周报'),
                  Tab(text: '红黑榜单'),
                  Tab(text: '餐后反馈'),
                ],
              ),
            ),
          ),
        ),
        // 三大子版块的页面分流容器
        body: TabBarView(
          physics: const BouncingScrollPhysics(), // 引入 iOS 风格的越界回弹手势，增加丝滑度
          children: [
            _WeeklyReportTab(controller: controller),
            _BlacklistTab(controller: controller),
            _FeedbackTab(controller: controller),
          ],
        ),
      ),
    );
  }
}

// ── 周报 Tab ─────────────────────────────────────────────────────────────────

/// 【类说明：周报数据统计视图 (智能画像展示模块)】
/// 作用：
/// 1. 响应式监听并展示用户本周的平均营养素摄入指标。
/// 2. 结合 FractionallySizedBox 渲染一整周的日均热量波动柱状图。
/// 3. 展示来自 AI 针对本周饮食漏洞下发的健康警告提醒和深度改善方案。
class _WeeklyReportTab extends StatelessWidget {
  const _WeeklyReportTab({required this.controller});
  final HealthReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 状态机流转 1：加载中状态反馈
      if (controller.isLoadingReport.value) {
        return const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))),
        );
      }
      
      final report = controller.weeklyReport.value;
      
      // 状态机流转 2：无数据时的空白占位提示
      if (report == null) {
        return EmptyState(
          icon: Icons.bar_chart_outlined,
          title: '暂无周报数据',
          message: '健康的真谛在于持续追踪，记录一餐来看看吧。',
          actionLabel: '刷新',
          onAction: controller.loadWeeklyReport,
        );
      }
      
      // 状态机流转 3：真实数据完美渲染列表
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // 顶置日期区间
          Text(
            '📅  ${report.weekStart} 至 ${report.weekEnd}',
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          
          // 核心数值仪表盘（包裹进规范的 SectionCard）
          SectionCard(
            title: '核心数据概览',
            child: GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 【已修复】：去除了错误的赋值符号
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 94, // 严格契合高度规范，杜绝溢出
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动，由外层 ListView 统一接管
              children: [
                StatTile(
                  title: '日均热量摄入',
                  value: report.avgCalories.toStringAsFixed(0),
                  unit: 'kcal',
                  icon: Icons.local_fire_department_rounded,
                ),
                StatTile(
                  title: '日均蛋白质',
                  value: report.avgProteinG.toStringAsFixed(1),
                  unit: 'g',
                  icon: Icons.fitness_center_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 柱状走势图组件动态拆装
          if (report.calorieTrend.isNotEmpty) ...[
            SectionCard(
              title: '本周热量走势分析',
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _CalorieTrendChart(trend: report.calorieTrend),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // 风险漏洞组件：健康警告提醒
          if (report.warnings.isNotEmpty) ...[
            SectionCard(
              title: '健康漏洞风险预警',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.warnings
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFFF9F43)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                w,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // AI大模型下发的深度优化建议
          if (report.suggestions.isNotEmpty) ...[
            SectionCard(
              title: 'AI 营养师深度改良方案',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.suggestions
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Color(0xFFEDFBF2), shape: BoxShape.circle),
                              child: const Icon(Icons.tips_and_updates_rounded, size: 16, color: Color(0xFF20BF6B)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), height: 1.4, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// 【类说明：旧版兼容卡片组件】
/// 作用：老版本中留下来的卡片组件，为了保障项目其他老代码或者历史合并时不发生编译级报错，予以原地保留。
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

/// 【类说明：周度热量走势微缩柱状图表】
/// 作用：
/// 1. 动态遍历传入的一周热量断点数据 [trend]。
/// 2. 自动定位本周最大峰值，利用 [FractionallySizedBox] 的高度比例系数 `heightFactor` 完美拉伸胶囊柱体。
class _CalorieTrendChart extends StatelessWidget {
  const _CalorieTrendChart({required this.trend});
  final List<CalorieTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();
    // 算法核心：找出热量的天花板上限，作为 100% 高度参照物
    final maxCal = trend.map((t) => t.calories).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 140, // 稍微挑高坐标系，让数值标签展示更具空灵感
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((t) {
          // 计算单根柱子的弹性膨胀比例
          final ratio = maxCal > 0 ? t.calories / maxCal : 0.0;
          // 裁剪截取日期标签，规避长文本在水平方向上的字符撞车
          final dayLabel = t.date.length >= 10 ? t.date.substring(5) : t.date;
          
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    t.calories.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio.clamp(0.08, 1.0), // 设立防低保下限，防止 0 热量时卡片彻底隐形
                        child: Container(
                          decoration: BoxDecoration(
                            // 呼应全局主色调的轻奢橙红渐变
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8E53), Color(0xFFFF6B35)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6), // 打造顶端的圆润胶囊手感
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(dayLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 红黑榜 Tab ───────────────────────────────────────────────────────────────

/// 【类说明：红黑榜双极推荐数据看板】
/// 作用：
/// 联动后端的 Apriori 关联算法分析，对容易引起用户胃胀、胃酸的食物进行标记拦截（黑榜）；
/// 同时对适配用户身体特质的优秀食材进行加分倾斜（红榜）。
class _BlacklistTab extends StatelessWidget {
  const _BlacklistTab({required this.controller});
  final HealthReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 状态捕获 1：列表异步拉取中
      if (controller.isLoadingBlacklist.value) {
        return const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))),
        );
      }
      
      final data = controller.blacklist.value;
      
      // 状态捕获 2：历史零记录空状态
      if (data == null) {
        return EmptyState(
          icon: Icons.rule_outlined,
          title: '暂无红黑榜分析',
          message: '数据算法正在根据你的‘餐后反馈’拼命计算中。',
          actionLabel: '重新加载',
          onAction: controller.loadBlacklist,
        );
      }
      
      // 状态捕获 3：双榜全装载滚动流
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // 【危险回避区 - 黑榜单】
          SectionCard(
            title: '黑榜（算法防坑 • 建议回避）',
            child: data.blackItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('环境表现极佳，本周暂无引起不适的黑榜食物', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                  )
                : Column(
                    children: data.blackItems.map((item) => _BlackItemCard(item: item)).toList(),
                  ),
          ),
          const SizedBox(height: 24),
          
          // 【营养加码区 - 红榜单】
          SectionCard(
            title: '红榜（智能画像 • 推荐食用）',
            child: data.redItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('暂无高分红榜食材，快去录入单餐反馈吧', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13)),
                  )
                : Column(
                    children: data.redItems.map((item) => _RedItemCard(item: item)).toList(),
                  ),
          ),
        ],
      );
    });
  }
}

/// 【类说明：黑榜危险拦截单个信息卡片】
/// 视觉特质：淡红（0xFFFFEBEE）圆形警示图标，右侧高亮透出算法评估的致病“置信度（Confidence）”
class _BlackItemCard extends StatelessWidget {
  const _BlackItemCard({required this.item});
  final BlacklistItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFB), // 带有极其微弱的警示暖白红底色
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD2D6).withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFEBEE),
          child: Icon(Icons.no_food_rounded, color: Color(0xFFFF4757), size: 20),
        ),
        title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E), fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.reason, style: const TextStyle(color: Color(0xFF636E72), fontSize: 12, height: 1.3)),
              if (item.suggestion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text('💡 替换建议：${item.suggestion}', style: const TextStyle(color: Color(0xFFFF9F43), fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${(item.confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF4757), fontSize: 16),
            ),
            const SizedBox(height: 2),
            const Text('置信度', style: TextStyle(fontSize: 9, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold)),
          ],
        ),
        isThreeLine: item.suggestion != null,
      ),
    );
  }
}

/// 【类说明：红榜优质食材单体推荐卡片】
/// 视觉特质：浅绿（0xFFE8F5E9）复选标识环，右侧大字号突出大模型权重的综合健康加分。
class _RedItemCard extends StatelessWidget {
  const _RedItemCard({required this.item});
  final RedlistItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC2EABD).withOpacity(0.4), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.check_circle_outline_rounded, color: Color(0xFF20BF6B), size: 20),
        ),
        title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E), fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(item.reason, style: const TextStyle(color: Color(0xFF636E72), fontSize: 12, height: 1.3)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              item.score.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF20BF6B), fontSize: 18),
            ),
            const SizedBox(height: 2),
            const Text('推崇评分', style: TextStyle(fontSize: 9, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ── 餐后反馈 Tab ─────────────────────────────────────────────────────────────

/// 【类说明：餐后生理表现历史归档流视图】
/// 作用：
/// 1. 响应式监听并使用 [ListView.builder] 架构纵向平铺用户过往录入的所有不适症状反馈。
/// 2. 右下角悬浮一个高维的 [FloatingActionButton.extended]，点击后安全唤醒包含全套交互式逻辑的底部表单抽屉。
class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.controller});
  final HealthReportController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Obx(() {
        // 无反馈记录时的全幅画布占位
        if (controller.feedbacks.isEmpty) {
          return const EmptyState(
            icon: Icons.feedback_outlined,
            title: '还没有录入身体状态',
            message: '每一餐后的饱腹度与困倦度，都是 AI 矫正推荐特征的重要线索哦。',
          );
        }
        
        // 瀑布流渲染归档列表
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90), // 底部预留 90px，防范 FAB 发生不可逆的视觉遮挡
          itemCount: controller.feedbacks.length,
          itemBuilder: (context, index) {
            return _FeedbackCard(feedback: controller.feedbacks[index]);
          },
        );
      }),
      // 右下角悬浮延伸按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true, // 准许高度冲破界限，配合软键盘自动抬升
          useSafeArea: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _AddFeedbackSheet(controller: controller),
        ),
        backgroundColor: const Color(0xFF1C1C1E), // 现代黑武士黑极简格调
        elevation: 6,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
        label: const Text('新增餐后状态', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}

/// 【类说明：单次归档餐后数据展示瓦片卡片】
/// 作用：解包并渲染单次餐后记录，自动利用字典将英文标识（'great'）转译为优雅的中文情绪标签（'很好'）。
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final HealthFeedbackModel feedback;

  // 国际化静态语义软映射字典
  static const Map<String, String> _moodLabels = {
    'great': '🔥 状态极佳',
    'good': '😊 舒适满足',
    'normal': '🙂 表现平稳',
    'bad': '🥱 略感不适',
    'terrible': '🤢 极其糟糕',
  };

  @override
  Widget build(BuildContext context) {
    final moodLabel = _moodLabels[feedback.mood] ?? feedback.mood;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 对齐字段映射：流水单号 & 精准裁剪到分钟的时间锚点
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
                child: Text('流水记录 #${feedback.foodRecordId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1C1C1E))),
              ),
              const Spacer(),
              Text(
                feedback.feedbackTime.length >= 16 ? feedback.feedbackTime.substring(0, 16) : feedback.feedbackTime,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // 生物体征多色级联标签横向排布
          Row(
            children: [
              _LevelChip(label: '腹胀度', level: feedback.bloatingLevel, max: 5),
              const SizedBox(width: 8),
              _LevelChip(label: '疲劳感', level: feedback.fatigueLevel, max: 5),
              const SizedBox(width: 8),
              // 综合情绪状态表现瓦片
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFEFEFF4))),
                child: Text(moodLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              ),
            ],
          ),
          
          // 用户的历史感性备忘描述
          if (feedback.digestiveNote != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(12)),
              child: Text(
                '✍️ 消化备注：${feedback.digestiveNote!}',
                style: const TextStyle(color: Color(0xFF636E72), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          
          // 衍生症状并发标签高级聚合排版区
          if (feedback.extraSymptoms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: feedback.extraSymptoms
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFF4757).withOpacity(0.15)),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 10, color: Color(0xFFFF4757), fontWeight: FontWeight.bold)),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// 【类说明：三色安全警告胶囊标签】
/// 核心渲染逻辑：自动根据级别系数（1安全绿、3轻微黄、5危险红）改变芯片前景色、背景色和边框颜色。
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label, required this.level, required this.max});
  final String label;
  final int level;
  final int max;

  @override
  Widget build(BuildContext context) {
    Color itemColor = const Color(0xFF20BF6B); // 级配 1：绿色安宁
    if (level > 1 && level <= 3) itemColor = const Color(0xFFFFCC00); // 级配 2：局黄警惕
    if (level > 3) itemColor = const Color(0xFFFF4757); // 级配 3：赤红风险

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: itemColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: itemColor.withOpacity(0.3)),
      ),
      child: Text(
        '$label $level/$max',
        // 【已修复】：将不合法的 FontWeight.black 修改为了最粗的 w900
        style: TextStyle(color: itemColor, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

// ── 新增反馈底部表单抽屉 ──────────────────────────────────────────────────────────

/// 【类说明：全功能交互式餐后状态添加舱 (高级 Stateful 弹窗)】
/// 作用：
/// 1. 挂载全局 `Form` 安全表单验证钩子。
/// 2. 使用 [MediaQuery.viewInsetsOf] 动态嗅探系统软键盘的顶推弹起像素，实现无死角抗遮挡。
/// 3. 内置数据表单验证、症状多选、心情下拉映射、防多开防重复提交的安全异步防护体系。
class _AddFeedbackSheet extends StatefulWidget {
  const _AddFeedbackSheet({required this.controller});
  final HealthReportController controller;

  @override
  State<_AddFeedbackSheet> createState() => _AddFeedbackSheetState();
}

class _AddFeedbackSheetState extends State<_AddFeedbackSheet> {
  // 核心控制总线
  final _formKey = GlobalKey<FormState>();
  final _recordIdCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  // 核心打包契约状态（完全保留并初始化你的后端字段）
  int _bloatingLevel = 0;
  int _fatigueLevel = 0;
  String _mood = 'normal';
  final Set<String> _symptoms = {};

  // 下拉项常量语义装载
  static const List<DropdownMenuItem<String>> _moodItems = [
    DropdownMenuItem(value: 'great', child: Text('🔥 状态极佳', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'good', child: Text('😊 舒适满足', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'normal', child: Text('🙂 表现平稳', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'bad', child: Text('🥱 略感不适', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'terrible', child: Text('🤢 极其糟糕', style: TextStyle(fontWeight: FontWeight.bold))),
  ];

  static const List<String> _symptomOptions = ['thirsty', 'bloated', 'nausea', 'heartburn', 'drowsy'];

  static const Map<String, String> _symptomLabels = {
    'thirsty': '口渴',
    'bloated': '腹胀',
    'nausea': '恶心',
    'heartburn': '胃灼热',
    'drowsy': '困倦',
  };

  @override
  void dispose() {
    _recordIdCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// 【核心网络功能函数：跨层异步网路数据投递】
  /// 难点/核心逻辑：
  /// 1. 激活 `_formKey.currentState?.validate()`，若输入为空或非法，拦截线程并原地阻断抛红。
  /// 2. 打包滑块和 Set 集合（转为标准 List），全量投递给 [HealthReportController.submitFeedback]。
  /// 3. 拦截处理提交返回结果，触发 SnackBar 并完成弹窗自动关闭。
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    // 调用控制器底层网络契约，完全保留你原本的 submitFeedback 入参结构
    final ok = await widget.controller.submitFeedback(
      foodRecordId: int.parse(_recordIdCtrl.text.trim()),
      bloatingLevel: _bloatingLevel,
      fatigueLevel: _fatigueLevel,
      mood: _mood,
      digestiveNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      extraSymptoms: _symptoms.toList(),
    );
    
    // 网络级回调 UI 真实响应
    if (ok && mounted) {
      Navigator.of(context).pop(); // 销毁当前弹窗
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 反馈已提交'),
          backgroundColor: Color(0xFF20BF6B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 录入失败：${widget.controller.errorMessage.value}'),
          backgroundColor: const Color(0xFFFF4757),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom, // 【防遮挡核心】：实时测算软键盘高度并托起整个表单底座
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶置标题横格线
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '新增餐后反馈',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w900, // 修正为合法的最粗字重，替代错误的 black
                          color: Color(0xFF1C1C1E),    // 高质感现代黑
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 输入框组 1：绑定单餐流水 ID * (完全集成原本的 validator)
                TextFormField(
                  controller: _recordIdCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '饮食记录 ID*',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    helperText: '填写关联的饮食记录编号',
                    helperStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFFFF6B35), size: 18),
                  ),
                  validator: (v) => int.tryParse(v ?? '') == null ? '请填写有效的记录 ID' : null,
                ),
                const SizedBox(height: 16),
                
                // 输入框组 2：下拉选择整体感受
                DropdownButtonFormField<String>(
                  value: _mood,
                  decoration: InputDecoration(
                    labelText: '整体感受',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.mood_rounded, color: Color(0xFFFFCC00), size: 18),
                  ),
                  items: _moodItems,
                  onChanged: (v) => setState(() => _mood = v!),
                ),
                const SizedBox(height: 20),
                
                // 特征模块 3：腹胀感、疲劳感双滑块联动舱 (【已修复】：crossAxisAlignment 重叠错字)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFAFAFA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEFEFF4))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SliderField(
                        label: '腹胀程度',
                        value: _bloatingLevel,
                        max: 5,
                        onChanged: (v) => setState(() => _bloatingLevel = v),
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFEFEFF4))),
                      _SliderField(
                        label: '疲劳程度',
                        value: _fatigueLevel,
                        max: 5,
                        onChanged: (v) => setState(() => _fatigueLevel = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // 特征模块 4：并发身体特征多选 FilterChip 组 (100% 对齐原版 symptomLabels 的原始英文 Value 压栈)
                const Text('其他症状', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _symptomOptions.map((s) {
                    final selected = _symptoms.contains(s);
                    return FilterChip(
                      label: Text(_symptomLabels[s] ?? s),
                      selected: selected,
                      labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF1C1C1E), fontSize: 12, fontWeight: FontWeight.bold),
                      selectedColor: const Color(0xFFFF4757),
                      checkmarkColor: Colors.white,
                      backgroundColor: const Color(0xFFF2F2F7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      onSelected: (v) => setState(() {
                        if (v) { _symptoms.add(s); } // 存入原生的英文标识，确保提交数据格式对齐后端
                        else { _symptoms.remove(s); }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                
                // 消化备注可选大框
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: '消化备注（可选）',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 提交执行按钮（挂载响应式防多开转圈状态）
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: widget.controller.isSubmittingFeedback.value ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: widget.controller.isSubmittingFeedback.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Text('提交反馈', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 【类说明：单行数据刻度滑动条组件】
/// 作用：配合滑块在有限像素内精美输出 0-5 的刻度，带有专属的高亮色彩反馈。
class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
            Text('$value/$max', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFFF6B35))),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0, // 严格保持原版的 0 为起始点，完美吻合新增反馈初始值设定
          max: max.toDouble(),
          divisions: max,
          label: value.toString(),
          activeColor: const Color(0xFFFF6B35),
          inactiveColor: const Color(0xFFEFEFF4),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}