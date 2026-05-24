// frontend/lib/pages/food_record/food_record_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/empty_state.dart';
import '../../controllers/food_record_controller.dart';
import '../../models/food_record_model.dart';
import 'food_video_entry_page.dart';

/// 【类说明：FlavorLog 智慧饮食记录中心主页面】
/// 作用：
/// 纵向聚合渲染用户选定日期的已摄入饮食总线列表，支持日期回溯选择及多维度 AI/手动录入。
/// 
/// 视觉全面跃升：
/// 剔除了原生粗糙的 StatTile 和灰底卡片，全盘引入与“赛博冰箱”完全一致的
/// “流光渐变大卡 + Bento 纯白悬浮微距阴影卡牌”设计语言！
class FoodRecordPage extends StatelessWidget {
  const FoodRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FoodRecordController>();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 现代极简微灰底色
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '饮食记录',
          style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF6B35), size: 22),
            tooltip: '选择日期',
            onPressed: () => _pickDate(context, controller), 
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _DateBar(controller: controller),
          _SummaryBar(controller: controller),
          Expanded(
            child: _RecordList(controller: controller),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, controller),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          '新增饮食记录',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, FoodRecordController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B35), 
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C1C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await controller.changeDate(picked); 
    }
  }

  void _showAddOptions(BuildContext context, FoodRecordController controller) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFEAA7).withOpacity(0.4), shape: BoxShape.circle),
                child: const Icon(Icons.videocam_outlined, color: Color(0xFFE1B12C), size: 22),
              ),
              title: const Text('AI 智慧视频录入', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
              subtitle: const Text('录制餐食视频，AI 大模型秒级智能识别成分', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              onTap: () async {
                Navigator.pop(context);
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const FoodVideoEntryPage()),
                );
                if (ok == true) controller.loadRecords();
              },
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1, color: Color(0xFFF2F2F7))),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFF74B9FF).withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.edit_outlined, color: Color(0xFF0984E3), size: 22),
              ),
              title: const Text('常规手动录入', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E))),
              subtitle: const Text('逐项细化填写食物名称、卡路里及三大营养素', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              onTap: () {
                Navigator.pop(context);
                _showAddDialog(context, controller);
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, FoodRecordController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, 
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddRecordSheet(controller: controller),
    );
  }
}

// ── 日期标题栏 ────────────────────────────────────────────────────────────────

/// [_DateBar] 展示当前日期，并提供「前一天 / 后一天」快捷导航。
class _DateBar extends StatelessWidget {
  const _DateBar({required this.controller});
  final FoodRecordController controller;

  String _label(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final t = DateTime(d.year, d.month, d.day);
    if (t == today) return '今天';
    if (t == today.subtract(const Duration(days: 1))) return '昨天';
    return '${d.year}年${d.month.toString().padLeft(2, '0')}月${d.day.toString().padLeft(2, '0')}日';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = controller.selectedDate.value;
      final now = DateTime.now();
      final isToday =
          d.year == now.year && d.month == now.month && d.day == now.day;
      return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            // 前一天
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  controller.changeDate(d.subtract(const Duration(days: 1))),
            ),
            // 日期标题（可点击唤起日历）
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: d,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) controller.changeDate(picked);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event_note, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _label(d),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (!isToday) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => controller.changeDate(DateTime.now()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('回今天',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 后一天（今天不可前进）
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: isToday ? Colors.grey.shade400 : null,
              ),
              onPressed: isToday
                  ? null
                  : () => controller
                      .changeDate(d.add(const Duration(days: 1))),
            ),
          ],
        ),
      );
    });
  }
}

// ── 当日营养汇总 (彻底重构成赛博冰箱流光 Bento 风格) ───────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.records.isEmpty) return const SizedBox.shrink();
      
      // 前端抗打击动态聚合算法保留
      double computedTotalKcal = 0;
      double computedTotalProtein = 0;
      double computedTotalFat = 0;
      double computedTotalCarb = 0;

      for (var record in controller.records) {
        for (var item in record.items) {
          computedTotalKcal += item.calories;
          computedTotalProtein += item.proteinG;
          computedTotalFat += item.fatG;
          computedTotalCarb += item.carbohydrateG;
        }
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            // 顶部：大比重流光热量大盘
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
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
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                          child: const Text("今日累计热量", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(computedTotalKcal.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 4),
                            Text("kcal", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 36),
                  )
                ],
              ),
            ),
            const SizedBox(height: 14),
            
            // 底部：三大宏观营养素 Bento 纯白卡片并排
            Row(
              children: [
                Expanded(child: _buildMacroCard("蛋白质", computedTotalProtein, const Color(0xFF5AC8FA), Icons.fitness_center_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildMacroCard("脂肪", computedTotalFat, const Color(0xFFFFCC00), Icons.water_drop_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildMacroCard("碳水", computedTotalCarb, const Color(0xFF4CD964), Icons.grain_rounded)),
              ],
            )
          ],
        ),
      );
    });
  }

  /// 封装：微距阴影营养素白卡
  Widget _buildMacroCard(String label, double value, Color iconColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
        ]
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
              const SizedBox(width: 2),
              const Text("g", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── 记录列表 ────────────────────────────────────────────────────────────────

// 餐次顺序、标签、图标、背景色
const _kMealOrder = ['breakfast', 'lunch', 'dinner', 'snack'];
const _kMealLabels = {
  'breakfast': '早餐',
  'lunch': '午餐',
  'dinner': '晚餐',
  'snack': '加餐',
};
const _kMealIcons = {
  'breakfast': Icons.wb_sunny_outlined,
  'lunch': Icons.lunch_dining,
  'dinner': Icons.dinner_dining,
  'snack': Icons.cookie_outlined,
};
const _kMealColors = {
  'breakfast': Color(0xFFFFF3CD),
  'lunch': Color(0xFFD4EDDA),
  'dinner': Color(0xFFCCE5FF),
  'snack': Color(0xFFF8D7DA),
};

/// [_RecordList] 按餐次（早/午/晚/加餐）分组展示当天饮食记录。
class _RecordList extends StatelessWidget {
  const _RecordList({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.only(top: 100),
          child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)))),
        );
      }
      
      if (controller.errorMessage.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 60),
          child: EmptyState(
            icon: Icons.cloud_off_outlined,
            title: '加载失败啦',
            message: controller.errorMessage.value,
            actionLabel: '重试刷新',
            onAction: controller.loadRecords,
          ),
        );
      }
      
      if (controller.records.isEmpty) {
        return const EmptyState(
          icon: Icons.restaurant_menu_outlined,
          title: '还没有饮食记录',
          message: '点击右下角"新增记录"，开始记录今天的饮食吧。',
        );
      }

      // 按餐次分组
      final grouped = <String, List<FoodRecordModel>>{};
      for (final r in controller.records) {
        grouped.putIfAbsent(r.mealType, () => []).add(r);
      }
      // 按固定顺序排列，未知餐次附加到末尾
      final keys = [
        ..._kMealOrder.where(grouped.containsKey),
        ...grouped.keys.where((k) => !_kMealOrder.contains(k)),
      ];

      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        physics: const BouncingScrollPhysics(),
        children: keys.map((meal) {
          final recs = grouped[meal]!;
          final totalCal = recs.fold(0.0, (s, r) => s + r.totalCalories);
          return _MealGroup(
            mealType: meal,
            records: recs,
            totalCalories: totalCal,
            controller: controller,
          );
        }).toList(),
      );
    });
  }
}

/// 单个餐次分组：顶部色块标题 + 该餐次所有 [_RecordCard]
class _MealGroup extends StatelessWidget {
  const _MealGroup({
    required this.mealType,
    required this.records,
    required this.totalCalories,
    required this.controller,
  });
  final String mealType;
  final List<FoodRecordModel> records;
  final double totalCalories;
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    final label = _kMealLabels[mealType] ?? mealType;
    final icon = _kMealIcons[mealType] ?? Icons.restaurant;
    final bg = _kMealColors[mealType] ?? const Color(0xFFEEEEEE);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Text('${totalCalories.toStringAsFixed(0)} kcal',
                  style:
                      const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        ...records.map((r) =>
            _RecordCard(record: r, controller: controller)),
      ],
    );
  }
}

// ── 单条记录卡片 ───────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.controller});
  final FoodRecordModel record;
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    final mealLabel = _kMealLabels[record.mealType] ?? record.mealType;
    final mealIcon = _kMealIcons[record.mealType] ?? Icons.restaurant;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(mealIcon, color: Theme.of(context).colorScheme.primary),
        title: Text(mealLabel,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${record.totalCalories.toStringAsFixed(0)} kcal'
          '${record.description != null ? '  ·  ${record.description}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4757), size: 20),
              tooltip: '删除',
              onPressed: () => _confirmDelete(context),
            ),
            const Icon(Icons.expand_more_rounded, color: Color(0xFFC7C7CC), size: 22),
          ],
        ),
        children: [
          if (record.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, thickness: 0.5, color: Color(0xFFF2F2F7)),
                  const SizedBox(height: 10),
                  ...record.items.map(_buildItemRow),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemRow(FoodItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${item.foodName}  ${item.weightG.toStringAsFixed(0)}g',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(6)),
            child: Text(
              '${item.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认删除吗？', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        content: const Text('饮食明细一旦抹除，相关的今日 AI 膳食密语和周度报告权重将同步发生深度缩减，不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消留着', style: TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final ok = await controller.deleteRecord(record.id); 
              
              if (ok) {
                controller.loadRecords(); 
              } else if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(controller.errorMessage.value), backgroundColor: const Color(0xFFFF4757), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('执意删除', style: TextStyle(color: Color(0xFFFF4757), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── 新增记录底部表单 ────────────────────────────────────────────────────────

class _AddRecordSheet extends StatefulWidget {
  const _AddRecordSheet({required this.controller});
  final FoodRecordController controller;

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _formKey = GlobalKey<FormState>();
  String _mealType = 'lunch';
  DateTime _recordTime = DateTime.now();
  final _descController = TextEditingController();

  final List<_FoodItemForm> _itemForms = [_FoodItemForm()];

  static const List<DropdownMenuItem<String>> _mealItems = [
    DropdownMenuItem(value: 'breakfast', child: Text('🌅 早餐', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'lunch', child: Text('☀️ 午餐', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'dinner', child: Text('🌙 晚餐', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'snack', child: Text('🍎 加餐', style: TextStyle(fontWeight: FontWeight.bold))),
  ];

  @override
  void dispose() {
    _descController.dispose();
    for (final f in _itemForms) {
      f.dispose(); 
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: const Text(
                        '新增饮食记录',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: _mealType,
                  decoration: InputDecoration(
                    labelText: '选定餐次',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF6B35), size: 18),
                  ),
                  items: _mealItems,
                  onChanged: (v) => setState(() => _mealType = v!),
                ),
                const SizedBox(height: 14),
                
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Text(
                    '精确定位：${_recordTime.hour.toString().padLeft(2, '0')}:${_recordTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  trailing: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF5AC8FA), size: 20),
                  onTap: _pickTime,
                  tileColor: const Color(0xFFF2F2F7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 14),
                
                TextFormField(
                  controller: _descController,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: '餐单细节备注（可选）',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    hintText: '例：少油少盐、少放了沙拉酱...',
                    hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF4CD964), size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    const Expanded(
                      child: Text('核心食物成分细化', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1C1C1E))),
                    ),
                    TextButton.icon(
                      onPressed: _addItem, 
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFFF6B35)),
                      label: const Text('添加单项食材', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                ..._itemForms.asMap().entries.map(
                      (e) => _FoodItemFormWidget(
                        key: ValueKey(e.key),
                        form: e.value,
                        onRemove: _itemForms.length > 1 ? () => _removeItem(e.key) : null, 
                      ),
                    ),
                const SizedBox(height: 24),
                
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: widget.controller.isSubmitting.value ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: widget.controller.isSubmitting.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Text('安全保存此餐数据', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _recordTime.hour, minute: _recordTime.minute),
    );
    if (picked != null) {
      setState(() {
        _recordTime = DateTime(_recordTime.year, _recordTime.month, _recordTime.day, picked.hour, picked.minute);
      });
    }
  }

  void _addItem() {
    setState(() => _itemForms.add(_FoodItemForm()));
  }

  void _removeItem(int index) {
    setState(() {
      _itemForms[index].dispose(); 
      _itemForms.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    final items = _itemForms
        .map((f) => f.toModel())
        .whereType<FoodItemModel>()
        .toList();
        
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 请至少完整填写一种食物的信息哦'), backgroundColor: Color(0xFFFFCC00), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    final ok = await widget.controller.createRecord(
      mealType: _mealType,
      recordTime: _recordTime,
      sourceType: 'manual',
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      items: items,
    );
    
    if (ok && mounted) {
      Navigator.of(context).pop();
      widget.controller.loadRecords(); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 记录已成功保存，今日摘要已同步重算！'), backgroundColor: Color(0xFF20BF6B), behavior: SnackBarBehavior.floating),
      );
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage.value), backgroundColor: const Color(0xFFFF4757), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// ── 单个食物行表单数据 ─────────────────────────────────────────────────────

class _FoodItemForm {
  final nameCtrl = TextEditingController();
  final weightCtrl = TextEditingController();
  final caloriesCtrl = TextEditingController();
  final proteinCtrl = TextEditingController();
  final fatCtrl = TextEditingController();
  final carbCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    weightCtrl.dispose();
    caloriesCtrl.dispose();
    proteinCtrl.dispose();
    fatCtrl.dispose();
    carbCtrl.dispose();
  }

  FoodItemModel? toModel() {
    final name = nameCtrl.text.trim();
    final weight = double.tryParse(weightCtrl.text.trim());
    final calories = double.tryParse(caloriesCtrl.text.trim());
    if (name.isEmpty || weight == null || calories == null) return null;
    return FoodItemModel(
      foodName: name,
      weightG: weight,
      calories: calories,
      proteinG: double.tryParse(proteinCtrl.text.trim()) ?? 0,
      fatG: double.tryParse(fatCtrl.text.trim()) ?? 0,
      carbohydrateG: double.tryParse(carbCtrl.text.trim()) ?? 0,
    );
  }
}

// ── 单个食物行表单 UI ──────────────────────────────────────────────────────

class _FoodItemFormWidget extends StatelessWidget {
  const _FoodItemFormWidget({
    super.key,
    required this.form,
    this.onRemove,
  });
  final _FoodItemForm form;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFEFF4), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: form.nameCtrl,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration('食物名称 *', Icons.restaurant_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? '请填写食物名称' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: form.weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration('重量(g) *', Icons.scale_rounded),
                  validator: (v) => (double.tryParse(v ?? '') == null) ? '请填写重量' : null,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFFF4757), size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: form.caloriesCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: _buildCompactInputDecoration('热量*'),
                  validator: (v) => (double.tryParse(v ?? '') == null) ? '请填写热量' : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: form.proteinCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: _buildCompactInputDecoration('蛋白(g)'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: form.fatCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: _buildCompactInputDecoration('脂肪(g)'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  controller: form.carbCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  decoration: _buildCompactInputDecoration('碳水(g)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w600),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF6B35))),
      prefixIcon: Icon(icon, color: const Color(0xFFC7C7CC), size: 14),
    );
  }

  InputDecoration _buildCompactInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 10, fontWeight: FontWeight.bold),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFF6B35))),
    );
  }
}