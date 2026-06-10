// frontend/lib/pages/health_report/health_report_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';

import '../../components/empty_state.dart';
import '../../controllers/food_record_controller.dart';
import '../../controllers/health_report_controller.dart';
import '../../models/food_record_model.dart';
import '../../models/health_model.dart';

/// 【类说明：FlavorLog 智慧健康数据报告主控制台】
/// 作用：
/// 本页面作为用户饮食数据分析、AI 画像诊断和身体自主反馈的核心入口。
class HealthReportPage extends StatelessWidget {
  const HealthReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HealthReportController>();
    
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // 现代微灰底色
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
            onPressed: () => Get.back(), 
          ),
          title: const Text(
            '健康报告',
            style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFF4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                labelColor: const Color(0xFF1C1C1E),
                unselectedLabelColor: const Color(0xFF8E8E93),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))
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
        body: TabBarView(
          physics: const BouncingScrollPhysics(), 
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

// ── 周报 Tab (已彻底革除旧版灰色方块，全面升级为流光 Bento 网格) ───────────────

class _WeeklyReportTab extends StatelessWidget {
  const _WeeklyReportTab({required this.controller});
  final HealthReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingReport.value) {
        return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))));
      }
      
      final report = controller.weeklyReport.value;
      if (report == null) {
        return EmptyState(
          icon: Icons.bar_chart_outlined,
          title: '暂无周报数据',
          message: '健康的真谛在于持续追踪，记录一餐来看看吧。',
          actionLabel: '刷新',
          onAction: controller.loadWeeklyReport,
        );
      }
      
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // 1. 高颜值胶囊日期条
          _buildDatePill(report.weekStart, report.weekEnd),
          const SizedBox(height: 24),
          
          // 2. 核心数据双拼卡片 (取代了旧版的灰色 StatTile)
          Row(
            children: [
              Expanded(
                child: _buildGradientStatCard(
                  title: '日均热量摄入', 
                  value: report.avgCalories.toStringAsFixed(0), 
                  unit: 'kcal', 
                  icon: Icons.local_fire_department_rounded
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildWhiteStatCard(
                  title: '日均蛋白质', 
                  value: report.avgProteinG.toStringAsFixed(1), 
                  unit: 'g', 
                  icon: Icons.fitness_center_rounded,
                  iconColor: const Color(0xFF5AC8FA)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 3. 热量走势分析大盘
          if (report.calorieTrend.isNotEmpty)
            _buildChartCard(report.calorieTrend),
          
          // 4. 健康风险预警舱
          if (report.warnings.isNotEmpty)
            _buildWarningCard(report.warnings),
          
          // 5. AI 营养师改良方案舱
          if (report.suggestions.isNotEmpty)
            _buildSuggestionCard(report.suggestions),
            
          const SizedBox(height: 40),
        ],
      );
    });
  }

  /// 顶置日期胶囊
  Widget _buildDatePill(String start, String end) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text(
                '$start  至  $end',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 左侧：动感流光热量卡
  Widget _buildGradientStatCard({required String title, required String value, required String unit, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 右侧：微距纯白蛋白卡
  Widget _buildWhiteStatCard({required String title, required String value, required String unit, required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  /// 热量走势折线图卡片
  Widget _buildChartCard(List<CalorieTrendPoint> trend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("本周热量走势分析", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 24),
          _CalorieTrendChart(trend: trend),
        ],
      ),
    );
  }

  /// 危险漏洞预警卡片
  Widget _buildWarningCard(List<String> warnings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFFF4757).withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4757), size: 18),
              ),
              const SizedBox(width: 8),
              const Text("健康漏洞风险预警", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
            ],
          ),
          const SizedBox(height: 16),
          ...warnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: Color(0xFFFF4757), fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(child: Text(w, style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// AI 改良建议卡片
  Widget _buildSuggestionCard(List<String> suggestions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFF20BF6B).withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF20BF6B), size: 18),
              ),
              const SizedBox(width: 8),
              const Text("AI 营养师深度改良方案", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
            ],
          ),
          const SizedBox(height: 16),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: Color(0xFF20BF6B), fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50), height: 1.5))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// 【图表组件：周度热量走势柱状图表】
class _CalorieTrendChart extends StatelessWidget {
  const _CalorieTrendChart({required this.trend});
  final List<CalorieTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();
    final maxCal = trend.map((t) => t.calories).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 130, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((t) {
          final ratio = maxCal > 0 ? t.calories / maxCal : 0.0;
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
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: ratio.clamp(0.08, 1.0), 
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8E53), Color(0xFFFF6B35)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6), 
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(dayLabel, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
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

class _BlacklistTab extends StatelessWidget {
  const _BlacklistTab({required this.controller});
  final HealthReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingBlacklist.value) {
        return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35))));
      }
      final data = controller.blacklist.value;
      if (data == null) {
        return EmptyState(
          icon: Icons.rule_outlined,
          title: '暂无红黑榜数据',
          message: '',
          actionLabel: '刷新',
          onAction: controller.loadBlacklist,
        );
      }
      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // 黑榜
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('黑榜（建议回避）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 16),
                data.blackItems.isEmpty
                    ? const Text('暂无黑榜食物', style: TextStyle(color: Color(0xFF8E8E93)))
                    : Column(children: data.blackItems.map((item) => _BlackItemCard(item: item)).toList()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 红榜
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('红榜（推荐食用）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 16),
                data.redItems.isEmpty
                    ? const Text('暂无红榜食物', style: TextStyle(color: Color(0xFF8E8E93)))
                    : Column(children: data.redItems.map((item) => _RedItemCard(item: item)).toList()),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _BlackItemCard extends StatelessWidget {
  const _BlackItemCard({required this.item});
  final BlacklistItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD2D6).withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.no_food, color: Color(0xFFFF4757))),
        title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.reason, style: const TextStyle(fontSize: 12, color: Color(0xFF636E72))),
            if (item.suggestion != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('💡 建议：${item.suggestion}', style: const TextStyle(color: Color(0xFFFF9F43), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(item.confidence * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF4757), fontSize: 16)),
            const Text('置信度', style: TextStyle(fontSize: 9, color: Color(0xFF8E8E93))),
          ],
        ),
        isThreeLine: item.suggestion != null,
      ),
    );
  }
}

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.check_circle_outline, color: Color(0xFF20BF6B))),
        title: Text(item.foodName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(item.reason, style: const TextStyle(fontSize: 12, color: Color(0xFF636E72))),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.score.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF20BF6B), fontSize: 18)),
            const Text('评分', style: TextStyle(fontSize: 9, color: Color(0xFF8E8E93))),
          ],
        ),
      ),
    );
  }
}

// ── 餐后反馈 Tab ─────────────────────────────────────────────────────────────

class _FeedbackTab extends StatelessWidget {
  const _FeedbackTab({required this.controller});
  final HealthReportController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Obx(() {
        if (controller.feedbacks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40.0, left: 24, right: 24),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1C1C1E).withOpacity(0.015),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review_rounded, size: 48, color: Color(0xFFFF6B35)),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "暂无餐后感受反馈",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "身体是最好的晴雨表。记录下每餐之后的腹胀、疲劳情况与整体心境，AI 将帮您构建精准的专属红黑榜单！",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93), height: 1.6),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        builder: (_) => _AddFeedbackSheet(controller: controller),
                      ),
                      icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 16),
                      label: const Text("记录此刻身体状态", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        elevation: 3,
                        shadowColor: const Color(0xFFFF6B35).withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: controller.feedbacks.length,
          itemBuilder: (context, index) {
            return _FeedbackCard(feedback: controller.feedbacks[index]);
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _AddFeedbackSheet(controller: controller),
        ),
        backgroundColor: const Color(0xFF1C1C1E),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
        label: const Text('新增反馈', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final HealthFeedbackModel feedback;

  static const Map<String, String> _moodLabels = {
    'great': '🔥 状态极佳',
    'good': '😊 舒适满足',
    'normal': '🙂 表现平稳',
    'bad': '🥱 略感不适',
    'terrible': '🤢 极其糟糕',
  };

  static const Map<String, String> _symptomLabels = {
    'thirsty': '极端口渴',
    'bloated': '胃胀上气',
    'nausea': '恶心干呕',
    'heartburn': '胃部反酸',
    'drowsy': '深度困倦',
  };

  @override
  Widget build(BuildContext context) {
    final moodLabel = _moodLabels[feedback.mood] ?? feedback.mood;

    Color moodThemeColor = const Color(0xFFFF6B35);
    if (feedback.mood == 'great' || feedback.mood == 'good') moodThemeColor = const Color(0xFF20BF6B);
    if (feedback.mood == 'bad' || feedback.mood == 'terrible') moodThemeColor = const Color(0xFFFF4757);

    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C1E).withOpacity(0.025),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: const Color(0xFFEFEFF4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: moodThemeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 12, color: moodThemeColor),
                    const SizedBox(width: 4),
                    Text(
                      '记录单 #${feedback.foodRecordId}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: moodThemeColor),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFC7C7CC)),
              const SizedBox(width: 4),
              Text(
                feedback.feedbackTime.length >= 16 ? feedback.feedbackTime.substring(0, 16) : feedback.feedbackTime,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _LevelChip(label: '腹胀', level: feedback.bloatingLevel, max: 5),
              const SizedBox(width: 8),
              _LevelChip(label: '疲劳', level: feedback.fatigueLevel, max: 5),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEFEFF4)),
                ),
                child: Text(moodLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
              ),
            ],
          ),
          if (feedback.digestiveNote != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6), 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFEAA7).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✍️ ', style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Text(
                      feedback.digestiveNote!,
                      style: const TextStyle(color: Color(0xFF7F8C8D), fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (feedback.extraSymptoms.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: feedback.extraSymptoms
                  .map((s) {
                    final String label = _symptomLabels[s] ?? s;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4757).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF4757).withOpacity(0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(color: Color(0xFFFF4757), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(fontSize: 10, color: Color(0xFFFF4757), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label, required this.level, required this.max});
  final String label;
  final int level;
  final int max;

  @override
  Widget build(BuildContext context) {
    Color itemColor = const Color(0xFF20BF6B);
    if (level > 1 && level <= 3) itemColor = const Color(0xFFFFCC00);
    if (level > 3) itemColor = const Color(0xFFFF4757);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: itemColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: itemColor.withOpacity(0.2)),
      ),
      child: Text('$label $level/$max', style: TextStyle(color: itemColor, fontSize: 11, fontWeight: FontWeight.w900)),
    );
  }
}

// ── 新增反馈底部表单 ──────────────────────────────────────────────────────────

class _AddFeedbackSheet extends StatefulWidget {
  const _AddFeedbackSheet({required this.controller});
  final HealthReportController controller;

  @override
  State<_AddFeedbackSheet> createState() => _AddFeedbackSheetState();
}

class _AddFeedbackSheetState extends State<_AddFeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  int? _selectedRecordId;
  int _bloatingLevel = 0;
  int _fatigueLevel = 0;
  String _mood = 'normal';
  final Set<String> _symptoms = {};

  @override
  void initState() {
    super.initState();
    // 自动拉取饮食记录，确保下拉框有最新数据
    if (Get.isRegistered<FoodRecordController>()) {
      final foodCtrl = Get.find<FoodRecordController>();
      if (foodCtrl.records.isEmpty) {
        foodCtrl.loadRecords();
      } else {
        _selectedRecordId = foodCtrl.records.first.id;
      }
    }
  }

  static const Map<String, String> _mealTypeLabels = {
    'breakfast': '早餐',
    'lunch': '午餐',
    'dinner': '晚餐',
    'snack': '加餐',
  };

  String _recordLabel(FoodRecordModel r) {
    final meal = _mealTypeLabels[r.mealType] ?? r.mealType;
    final time = r.recordTime.length >= 16
        ? r.recordTime.substring(5, 16).replaceAll('T', ' ')
        : r.recordTime;
    return '#${r.id} · $meal · $time';
  }

  static const List<Map<String, String>> _moodOptions = [
    {'value': 'great', 'emoji': '🔥', 'label': '状态极佳'},
    {'value': 'good', 'emoji': '😊', 'label': '舒适满足'},
    {'value': 'normal', 'emoji': '🙂', 'label': '表现平稳'},
    {'value': 'bad', 'emoji': '🥱', 'label': '略感不适'},
    {'value': 'terrible', 'emoji': '🤢', 'label': '极其糟糕'},
  ];

  static const List<String> _symptomOptions = ['thirsty', 'bloated', 'nausea', 'heartburn', 'drowsy'];

  static const Map<String, String> _symptomLabels = {
    'thirsty': '极端口渴',
    'bloated': '胃胀上气',
    'nausea': '恶心干呕',
    'heartburn': '胃部反酸',
    'drowsy': '深度困倦',
  };

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
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
                Row(
                  children: [
                    const Expanded(child: Text('新增餐后反馈', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)))),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRecordPicker(),
                const SizedBox(height: 20),
                const Text('整体感受', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 12),
                
                // 横排 Emoji 表情点选舱，颜值拉满！
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _moodOptions.map((opt) {
                    final bool isSelected = _mood == opt['value'];
                    return GestureDetector(
                      onTap: () => setState(() => _mood = opt['value']!),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF6B35).withOpacity(0.12) : const Color(0xFFF2F2F7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: const Color(0xFFFF6B35).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ] : null,
                            ),
                            child: Text(opt['emoji']!, style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            opt['label']!,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFF8E8E93),
                            ),
                          )
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                _SliderField(label: '腹胀程度', value: _bloatingLevel, max: 5, onChanged: (v) => setState(() => _bloatingLevel = v)),
                const SizedBox(height: 16),
                _SliderField(label: '疲劳程度', value: _fatigueLevel, max: 5, onChanged: (v) => setState(() => _fatigueLevel = v)),
                const SizedBox(height: 24),
                const Text('其他伴随症状（可多选）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1C1C1E))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _symptomOptions.map((s) {
                    final selected = _symptoms.contains(s);
                    return FilterChip(
                      label: Text(_symptomLabels[s] ?? s),
                      selected: selected,
                      selectedColor: const Color(0xFFFF4757),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF1C1C1E), fontSize: 12, fontWeight: FontWeight.bold),
                      backgroundColor: const Color(0xFFF2F2F7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                      onSelected: (v) => setState(() {
                        if (v) { _symptoms.add(s); } else { _symptoms.remove(s); }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: '消化备注（可选）',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    hintText: '例：胃部轻微灼烧、有饱腹感...',
                    hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF20BF6B), size: 18),
                  ),
                ),
                const SizedBox(height: 28),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: widget.controller.isSubmittingFeedback.value ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C1E), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: widget.controller.isSubmittingFeedback.value
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : const Text('安全提交反馈', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedRecordId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('请先选择一条饮食记录'),
        backgroundColor: Color(0xFFFF4757),
      ));
      return;
    }

    final ok = await widget.controller.submitFeedback(
      foodRecordId: _selectedRecordId!,
      bloatingLevel: _bloatingLevel,
      fatigueLevel: _fatigueLevel,
      mood: _mood,
      digestiveNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      extraSymptoms: _symptoms.toList(),
    );
    
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 反馈已成功入库！'), backgroundColor: Color(0xFF20BF6B)));
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.controller.errorMessage.value), backgroundColor: const Color(0xFFFF4757)));
    }
  }

  Widget _buildRecordPicker() {
    if (!Get.isRegistered<FoodRecordController>()) {
      return _buildEmptyRecordHint();
    }
    final foodCtrl = Get.find<FoodRecordController>();
    return Obx(() {
      final records = foodCtrl.records.toList();
      if (records.isEmpty) {
        return _buildEmptyRecordHint();
      }
      final currentId = records.any((r) => r.id == _selectedRecordId)
          ? _selectedRecordId
          : records.first.id;
      if (currentId != _selectedRecordId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedRecordId = currentId);
        });
      }
      return DropdownButtonFormField<int>(
        value: currentId,
        isExpanded: true,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
        decoration: InputDecoration(
          labelText: '关联饮食记录 *',
          labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
          filled: true,
          fillColor: const Color(0xFFF2F2F7),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFFFF6B35), size: 18),
        ),
        items: records
            .map((r) => DropdownMenuItem<int>(
                  value: r.id,
                  child: Text(_recordLabel(r), overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (v) => setState(() => _selectedRecordId = v),
        validator: (v) => v == null ? '请选择关联的饮食记录' : null,
      );
    });
  }

  Widget _buildEmptyRecordHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD6A8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFFF9F43), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '暂无饮食记录，请先到「饮食记录」页面添加一条后再来反馈～',
              style: TextStyle(color: Color(0xFFA0552D), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({required this.label, required this.value, required this.max, required this.onChanged});
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  String _levelText(int v) {
    if (v == 0) return '无感';
    if (v <= 2) return '轻微';
    if (v <= 4) return '中度';
    return '严重';
  }

  Color _levelColor(int v) {
    if (v == 0) return const Color(0xFF20BF6B);
    if (v <= 2) return const Color(0xFFFFCC00);
    return const Color(0xFFFF4757);
  }

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1C1C1E))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_levelText(value)} ($value/$max)',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withOpacity(0.12),
            inactiveTrackColor: const Color(0xFFF2F2F7),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: max.toDouble(),
            divisions: max,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}