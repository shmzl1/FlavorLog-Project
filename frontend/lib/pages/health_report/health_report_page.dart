import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/empty_state.dart';
import '../../components/section_card.dart';
import '../../components/stat_tile.dart';
import '../../controllers/health_report_controller.dart';
import '../../models/health_model.dart';

class HealthReportPage extends StatelessWidget {
  const HealthReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HealthReportController>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('健康报告'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: '周报'),
              Tab(icon: Icon(Icons.rule), text: '红黑榜'),
              Tab(icon: Icon(Icons.feedback_outlined), text: '餐后反馈'),
            ],
          ),
        ),
        body: TabBarView(
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

class _WeeklyReportTab extends StatelessWidget {
  const _WeeklyReportTab({required this.controller});
  final HealthReportController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingReport.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final report = controller.weeklyReport.value;
      if (report == null) {
        return EmptyState(
          icon: Icons.bar_chart_outlined,
          title: '暂无周报数据',
          message: '',
          actionLabel: '刷新',
          onAction: controller.loadWeeklyReport,
        );
      }
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 日期范围
          Text(
            '${report.weekStart} 至 ${report.weekEnd}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          // 核心指标
          SectionCard(
            title: '核心指标',
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 90,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatTile(
                  title: '日均热量',
                  value: report.avgCalories.toStringAsFixed(0),
                  unit: 'kcal',
                  icon: Icons.local_fire_department,
                ),
                StatTile(
                  title: '日均蛋白质',
                  value: report.avgProteinG.toStringAsFixed(1),
                  unit: 'g',
                  icon: Icons.fitness_center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 热量趋势
          if (report.calorieTrend.isNotEmpty) ...[
            SectionCard(
              title: '本周热量趋势',
              child: _CalorieTrendChart(trend: report.calorieTrend),
            ),
            const SizedBox(height: 16),
          ],
          // 警告
          if (report.warnings.isNotEmpty) ...[
            SectionCard(
              title: '健康提醒',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.warnings
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 6),
                            Expanded(child: Text(w)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 建议
          if (report.suggestions.isNotEmpty) ...[
            SectionCard(
              title: '改善建议',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: report.suggestions
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.tips_and_updates,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 6),
                            Expanded(child: Text(s)),
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
    // 已由 StatTile 替代，保留以免旧引用报错
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _CalorieTrendChart extends StatelessWidget {
  const _CalorieTrendChart({required this.trend});
  final List<CalorieTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();
    final maxCal = trend.map((t) => t.calories).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((t) {
          final ratio = maxCal > 0 ? t.calories / maxCal : 0.0;
          final dayLabel =
              t.date.length >= 10 ? t.date.substring(5) : t.date;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    t.calories.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  FractionallySizedBox(
                    heightFactor: ratio.clamp(0.05, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(dayLabel,
                      style:
                          const TextStyle(fontSize: 9, color: Colors.grey)),
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
        return const Center(child: CircularProgressIndicator());
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
        padding: const EdgeInsets.all(16),
        children: [
          // 黑榜
          SectionCard(
            title: '黑榜（建议回避）',
            child: data.blackItems.isEmpty
                ? const Text('暂无黑榜食物',
                    style: TextStyle(color: Colors.grey))
                : Column(
                    children:
                        data.blackItems.map((item) => _BlackItemCard(item: item)).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          // 红榜
          SectionCard(
            title: '红榜（推荐食用）',
            child: data.redItems.isEmpty
                ? const Text('暂无红榜食物',
                    style: TextStyle(color: Colors.grey))
                : Column(
                    children:
                        data.redItems.map((item) => _RedItemCard(item: item)).toList(),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFEBEE),
          child: Icon(Icons.no_food, color: Colors.red),
        ),
        title: Text(item.foodName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.reason),
            if (item.suggestion != null)
              Text('建议：${item.suggestion}',
                  style: const TextStyle(
                      color: Colors.orange, fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(item.confidence * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
            const Text('置信度', style: TextStyle(fontSize: 10)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.check_circle_outline, color: Colors.green),
        ),
        title: Text(item.foodName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(item.reason),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.score.toStringAsFixed(2),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green)),
            const Text('评分', style: TextStyle(fontSize: 10)),
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
      body: Obx(() {
        if (controller.feedbacks.isEmpty) {
          return const EmptyState(
            icon: Icons.feedback_outlined,
            title: '还没有餐后反馈',
            message: '点击右下角"新增反馈"，记录你的餐后感受吧。',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
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
          builder: (_) => _AddFeedbackSheet(controller: controller),
        ),
        icon: const Icon(Icons.add_comment),
        label: const Text('新增反馈'),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final HealthFeedbackModel feedback;

  static const Map<String, String> _moodLabels = {
    'great': '很好',
    'good': '良好',
    'normal': '一般',
    'bad': '不好',
    'terrible': '很差',
  };

  @override
  Widget build(BuildContext context) {
    final moodLabel = _moodLabels[feedback.mood] ?? feedback.mood;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('饮食记录 #${feedback.foodRecordId}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  feedback.feedbackTime.length >= 16
                      ? feedback.feedbackTime.substring(0, 16)
                      : feedback.feedbackTime,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LevelChip(
                    label: '腹胀',
                    level: feedback.bloatingLevel,
                    max: 5),
                const SizedBox(width: 8),
                _LevelChip(
                    label: '疲劳',
                    level: feedback.fatigueLevel,
                    max: 5),
                const SizedBox(width: 8),
                Chip(
                  label: Text(moodLabel),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (feedback.digestiveNote != null) ...[
              const SizedBox(height: 4),
              Text(feedback.digestiveNote!,
                  style: const TextStyle(color: Colors.grey)),
            ],
            if (feedback.extraSymptoms.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: feedback.extraSymptoms
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip(
      {required this.label, required this.level, required this.max});
  final String label;
  final int level;
  final int max;

  @override
  Widget build(BuildContext context) {
    final color = level <= 1
        ? Colors.green
        : level <= 3
            ? Colors.orange
            : Colors.red;
    return Chip(
      label: Text('$label $level/$max',
          style: TextStyle(color: color, fontSize: 11)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color),
      backgroundColor: color.withOpacity(0.08),
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
  final _recordIdCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _bloatingLevel = 0;
  int _fatigueLevel = 0;
  String _mood = 'normal';
  final Set<String> _symptoms = {};

  static const List<DropdownMenuItem<String>> _moodItems = [
    DropdownMenuItem(value: 'great', child: Text('很好')),
    DropdownMenuItem(value: 'good', child: Text('良好')),
    DropdownMenuItem(value: 'normal', child: Text('一般')),
    DropdownMenuItem(value: 'bad', child: Text('不好')),
    DropdownMenuItem(value: 'terrible', child: Text('很差')),
  ];

  static const List<String> _symptomOptions = [
    'thirsty',
    'bloated',
    'nausea',
    'heartburn',
    'drowsy',
  ];

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('新增餐后反馈',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recordIdCtrl,
                  decoration: const InputDecoration(
                    labelText: '饮食记录 ID*',
                    border: OutlineInputBorder(),
                    helperText: '填写关联的饮食记录编号',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? '请填写有效的记录 ID' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _mood,
                  decoration: const InputDecoration(
                    labelText: '整体感受',
                    border: OutlineInputBorder(),
                  ),
                  items: _moodItems,
                  onChanged: (v) => setState(() => _mood = v!),
                ),
                const SizedBox(height: 12),
                _SliderField(
                  label: '腹胀程度',
                  value: _bloatingLevel,
                  max: 5,
                  onChanged: (v) => setState(() => _bloatingLevel = v),
                ),
                const SizedBox(height: 4),
                _SliderField(
                  label: '疲劳程度',
                  value: _fatigueLevel,
                  max: 5,
                  onChanged: (v) => setState(() => _fatigueLevel = v),
                ),
                const SizedBox(height: 12),
                const Text('其他症状'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: _symptomOptions.map((s) {
                    final selected = _symptoms.contains(s);
                    return FilterChip(
                      label: Text(_symptomLabels[s] ?? s),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _symptoms.add(s);
                        } else {
                          _symptoms.remove(s);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: '消化备注（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          widget.controller.isSubmittingFeedback.value
                              ? null
                              : _submit,
                      child: widget.controller.isSubmittingFeedback.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : const Text('提交反馈'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.controller.submitFeedback(
      foodRecordId: int.parse(_recordIdCtrl.text.trim()),
      bloatingLevel: _bloatingLevel,
      fatigueLevel: _fatigueLevel,
      mood: _mood,
      digestiveNote:
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      extraSymptoms: _symptoms.toList(),
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('反馈已提交')),
      );
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage.value)),
      );
    }
  }
}

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
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text('$label $value/$max'),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: max.toDouble(),
            divisions: max,
            label: value.toString(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
