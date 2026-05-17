import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/empty_state.dart';
import '../../components/section_card.dart';
import '../../components/stat_tile.dart';
import '../../controllers/food_record_controller.dart';
import '../../models/food_record_model.dart';
import 'food_video_entry_page.dart';

/// [FoodRecordPage] 是饮食记录的主页面。
/// 包含顶部的日期选择、当天的营养数据汇总摘要（SummaryBar）以及详细的饮食记录列表。
class FoodRecordPage extends StatelessWidget {
  const FoodRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FoodRecordController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: '选择日期',
            onPressed: () => _pickDate(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          _DateBar(controller: controller),
          _SummaryBar(controller: controller),
          Expanded(child: _RecordList(controller: controller)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('新增记录'),
      ),
    );
  }

  /// 弹出日期选择器，供用户回溯或查看指定日期的饮食记录
  Future<void> _pickDate(
    BuildContext context,
    FoodRecordController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await controller.changeDate(picked);
    }
  }

  /// 点击“新增记录”后弹出的底部菜单
  /// 提供“视频录入(AI识别)”和“手动录入”两个选项
  void _showAddOptions(BuildContext context, FoodRecordController controller) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('视频录入'),
              subtitle: const Text('录制视频，AI 自动识别食物'),
              onTap: () async {
                Navigator.pop(context);
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FoodVideoEntryPage(),
                  ),
                );
                // 如果录入成功，重新拉取列表刷新数据
                if (ok == true) controller.loadRecords();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('手动录入'),
              subtitle: const Text('逐项填写食物信息'),
              onTap: () {
                Navigator.pop(context);
                _showAddDialog(context, controller);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 唤起手动新增记录的底部弹出表单
  void _showAddDialog(BuildContext context, FoodRecordController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // 允许弹窗充满全屏或根据键盘高度自适应
      useSafeArea: true,
      builder: (_) => _AddRecordSheet(controller: controller),
    );
  }
}

// ── 日期标题栏 ────────────────────────────────────────────────────────────────

/// [_DateBar] 用于展示当前选中的日期，使用 Obx 响应式刷新。
class _DateBar extends StatelessWidget {
  const _DateBar({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = controller.selectedDate.value;
      final label =
          '${d.year}年${d.month.toString().padLeft(2, '0')}月${d.day.toString().padLeft(2, '0')}日';
      return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.event_note, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      );
    });
  }
}

// ── 当日营养汇总 ────────────────────────────────────────────────────────────

/// [_SummaryBar] 用于展示当天所有记录的总营养素（热量、蛋白质、脂肪、碳水）。
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.records.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SectionCard(
          title: '今日营养摘要',
          // 【修复点】：将 GridView.count 替换为基础 GridView，并传入 gridDelegate。
          // SliverGridDelegateWithFixedCrossAxisCount 完美支持 mainAxisExtent 属性。
          child: GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 90, // 强制设置主轴方向（高度）为90
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // 禁用内部滚动，交给外部组件滚动
            children: [
              StatTile(
                title: '热量',
                value: controller.todayTotalCalories.toStringAsFixed(0),
                unit: 'kcal',
                icon: Icons.local_fire_department,
              ),
              StatTile(
                title: '蛋白质',
                value: controller.todayTotalProtein.toStringAsFixed(1),
                unit: 'g',
                icon: Icons.fitness_center,
              ),
              StatTile(
                title: '脂肪',
                value: controller.todayTotalFat.toStringAsFixed(1),
                unit: 'g',
                icon: Icons.water_drop,
              ),
              StatTile(
                title: '碳水',
                value: controller.todayTotalCarbohydrate.toStringAsFixed(1),
                unit: 'g',
                icon: Icons.grain,
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── 记录列表 ────────────────────────────────────────────────────────────────

/// [_RecordList] 负责渲染当天所有饮食记录的列表。
/// 处理了加载中、错误状态、空状态等 UI 逻辑。
class _RecordList extends StatelessWidget {
  const _RecordList({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return EmptyState(
          icon: Icons.cloud_off_outlined,
          title: '加载失败',
          message: controller.errorMessage.value,
          actionLabel: '重试',
          onAction: controller.loadRecords,
        );
      }
      if (controller.records.isEmpty) {
        return const EmptyState(
          icon: Icons.restaurant_menu_outlined,
          title: '今天还没有饮食记录',
          message: '点击右下角"新增记录"，开始记录今天的饮食吧。',
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: controller.records.length,
        itemBuilder: (context, index) {
          return _RecordCard(
            record: controller.records[index],
            controller: controller,
          );
        },
      );
    });
  }
}

// ── 单条记录卡片 ───────────────────────────────────────────────────────────

/// [_RecordCard] 渲染单条饮食记录（如"午餐"）。
/// 使用 ExpansionTile 提供可折叠展开的功能，展示该餐具体的食物项明细。
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.controller});
  final FoodRecordModel record;
  final FoodRecordController controller;

  static const Map<String, String> _mealLabels = {
    'breakfast': '早餐',
    'lunch': '午餐',
    'dinner': '晚餐',
    'snack': '加餐',
  };

  static const Map<String, IconData> _mealIcons = {
    'breakfast': Icons.wb_sunny_outlined,
    'lunch': Icons.lunch_dining,
    'dinner': Icons.dinner_dining,
    'snack': Icons.cookie_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final mealLabel = _mealLabels[record.mealType] ?? record.mealType;
    final mealIcon = _mealIcons[record.mealType] ?? Icons.restaurant;

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
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: '删除',
              onPressed: () => _confirmDelete(context),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (record.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  ...record.items.map(_buildItemRow),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建卡片折叠面板内单个食物项目的详情行
  Widget _buildItemRow(FoodItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${item.foodName}  ${item.weightG.toStringAsFixed(0)}g'),
          ),
          Text('${item.calories.toStringAsFixed(0)} kcal',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  /// 二次确认删除操作，防止误触
  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条饮食记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final ok = await controller.deleteRecord(record.id);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(controller.errorMessage.value)),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── 新增记录底部表单 ────────────────────────────────────────────────────────

/// [_AddRecordSheet] 手动新增记录信息的底部滑动表单（BottomSheet）。
/// 包含表单校验和动态增删食物项的逻辑。
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

  // 食物明细列表，支持用户添加多项食物
  final List<_FoodItemForm> _itemForms = [_FoodItemForm()];

  static const List<DropdownMenuItem<String>> _mealItems = [
    DropdownMenuItem(value: 'breakfast', child: Text('早餐')),
    DropdownMenuItem(value: 'lunch', child: Text('午餐')),
    DropdownMenuItem(value: 'dinner', child: Text('晚餐')),
    DropdownMenuItem(value: 'snack', child: Text('加餐')),
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
        // MediaQuery.viewInsetsOf(context).bottom 用来动态给软键盘留出空间
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '新增饮食记录',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 餐次
                DropdownButtonFormField<String>(
                  value: _mealType,
                  decoration: const InputDecoration(
                    labelText: '餐次',
                    border: OutlineInputBorder(),
                  ),
                  items: _mealItems,
                  onChanged: (v) => setState(() => _mealType = v!),
                ),
                const SizedBox(height: 12),
                // 时间
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      '记录时间：${_recordTime.hour.toString().padLeft(2, '0')}:${_recordTime.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _pickTime,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 12),
                // 备注
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // 食物明细
                Row(
                  children: [
                    const Expanded(
                      child: Text('食物明细',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加食物'),
                    ),
                  ],
                ),
                // 动态渲染用户填写的每一条食物表单项
                ..._itemForms.asMap().entries.map(
                      (e) => _FoodItemFormWidget(
                        key: ValueKey(e.key),
                        form: e.value,
                        onRemove: _itemForms.length > 1
                            ? () => _removeItem(e.key)
                            : null,
                      ),
                    ),
                const SizedBox(height: 16),
                // 提交按钮
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.controller.isSubmitting.value
                          ? null
                          : _submit,
                      child: widget.controller.isSubmitting.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存'),
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

  /// 唤起时间选择器
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: _recordTime.hour, minute: _recordTime.minute),
    );
    if (picked != null) {
      setState(() {
        _recordTime = DateTime(
          _recordTime.year,
          _recordTime.month,
          _recordTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  /// 追加一条空的食物录入项
  void _addItem() {
    setState(() => _itemForms.add(_FoodItemForm()));
  }

  /// 移除指定索引的食物录入项
  void _removeItem(int index) {
    setState(() {
      _itemForms[index].dispose();
      _itemForms.removeAt(index);
    });
  }

  /// 提交并保存整条饮食记录
  /// 会先校验表单字段，然后将 TextEditingController 中的数据转换为业务实体，调接口提交
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    // 过滤出有效的食物对象
    final items = _itemForms
        .map((f) => f.toModel())
        .whereType<FoodItemModel>()
        .toList();
        
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少填写一种食物')),
      );
      return;
    }
    
    final ok = await widget.controller.createRecord(
      mealType: _mealType,
      recordTime: _recordTime,
      sourceType: 'manual',
      description:
          _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      items: items,
    );
    
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('记录已保存')),
      );
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage.value)),
      );
    }
  }
}

// ── 单个食物行表单数据 ─────────────────────────────────────────────────────

/// [_FoodItemForm] 封装单个食物表单相关的所有 TextEditingController。
/// 提供 [toModel] 帮手函数用于将表单数据解析并生成 [FoodItemModel] 数据模型。
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

  /// 将输入框中的文本转为实际的实体模型。如果必填项缺失，返回 null。
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

/// [_FoodItemFormWidget] 渲染单行食物对应的输入框（名称、重量、热量及三大营养素）。
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: form.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '食物名称*',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '请填写食物名称' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: form.weightCtrl,
                    decoration: const InputDecoration(
                      labelText: '重量(g)*',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null) ? '请填写重量' : null,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: form.caloriesCtrl,
                    decoration: const InputDecoration(
                      labelText: '热量(kcal)*',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (double.tryParse(v ?? '') == null) ? '请填写热量' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: form.proteinCtrl,
                    decoration: const InputDecoration(
                      labelText: '蛋白质(g)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: form.fatCtrl,
                    decoration: const InputDecoration(
                      labelText: '脂肪(g)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: form.carbCtrl,
                    decoration: const InputDecoration(
                      labelText: '碳水(g)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}