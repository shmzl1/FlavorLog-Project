import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/food_record_controller.dart';
import '../../models/food_record_model.dart';

/// 视频录入结果确认页
/// 展示 AI 识别的饮食记录草稿，用户可编辑后保存
class FoodVideoResultPage extends StatefulWidget {
  /// 后端返回的草稿列表，每项对应一条 FoodRecordCreate
  final List<Map<String, dynamic>> drafts;

  const FoodVideoResultPage({super.key, required this.drafts});

  @override
  State<FoodVideoResultPage> createState() => _FoodVideoResultPageState();
}

class _FoodVideoResultPageState extends State<FoodVideoResultPage> {
  late String _mealType;
  late DateTime _recordTime;
  final _descCtrl = TextEditingController();
  late List<_EditableItem> _items;

  static const List<DropdownMenuItem<String>> _mealItems = [
    DropdownMenuItem(value: 'breakfast', child: Text('早餐')),
    DropdownMenuItem(value: 'lunch', child: Text('午餐')),
    DropdownMenuItem(value: 'dinner', child: Text('晚餐')),
    DropdownMenuItem(value: 'snack', child: Text('加餐')),
  ];

  @override
  void initState() {
    super.initState();
    final first =
        widget.drafts.isNotEmpty ? widget.drafts.first : <String, dynamic>{};
    _mealType = first['meal_type'] as String? ?? 'lunch';
    final rawTime = first['record_time'] as String?;
    _recordTime = (rawTime != null ? DateTime.tryParse(rawTime) : null) ??
        DateTime.now();
    _descCtrl.text = first['description'] as String? ?? '';

    // 合并所有草稿中的 items
    final rawItems = <Map<String, dynamic>>[];
    for (final draft in widget.drafts) {
      final items = draft['items'] as List<dynamic>? ?? [];
      rawItems.addAll(items.cast<Map<String, dynamic>>());
    }
    _items = rawItems.map(_EditableItem.fromJson).toList();
    if (_items.isEmpty) {
      _items.add(_EditableItem.empty());
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FoodRecordController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('确认食物信息'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // AI 识别横幅
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome,
                    color: Colors.green.shade700, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI 已识别 ${_items.length} 种食物，请确认并修正信息',
                    style: TextStyle(
                        color: Colors.green.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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

          // 记录时间
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '记录时间：'
              '${_recordTime.hour.toString().padLeft(2, '0')}:'
              '${_recordTime.minute.toString().padLeft(2, '0')}',
            ),
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
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // 食物列表标题
          Row(
            children: [
              const Expanded(
                child: Text(
                  '识别到的食物',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('手动添加'),
              ),
            ],
          ),

          // 食物明细卡片列表
          ..._items.asMap().entries.map(
                (e) => _ItemCard(
                  key: ValueKey(e.key),
                  item: e.value,
                  canRemove: _items.length > 1,
                  onRemove: () => setState(() {
                    _items[e.key].dispose();
                    _items.removeAt(e.key);
                  }),
                ),
              ),
        ],
      ),

      // 底部保存按钮
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Obx(
          () => FilledButton.icon(
            onPressed: controller.isSubmitting.value
                ? null
                : () => _save(controller),
            icon: controller.isSubmitting.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check),
            label: const Text('确认保存'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }

  void _addItem() => setState(() => _items.add(_EditableItem.empty()));

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

  Future<void> _save(FoodRecordController controller) async {
    final items = _items
        .map((e) => e.toModel())
        .whereType<FoodItemModel>()
        .toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少保留一种食物')),
      );
      return;
    }
    final ok = await controller.createRecord(
      mealType: _mealType,
      recordTime: _recordTime,
      sourceType: 'video_ai',
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      items: items,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('饮食记录已保存')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage.value)),
      );
    }
  }
}

// ── 单条食物明细（可编辑）────────────────────────────────────────────────────

class _EditableItem {
  final TextEditingController nameCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController caloriesCtrl;
  final TextEditingController proteinCtrl;
  final TextEditingController fatCtrl;
  final TextEditingController carbCtrl;
  final double confidence;

  _EditableItem({
    required String foodName,
    required double weightG,
    required double calories,
    double proteinG = 0,
    double fatG = 0,
    double carbohydrateG = 0,
    this.confidence = 1.0,
  })  : nameCtrl = TextEditingController(text: foodName),
        weightCtrl =
            TextEditingController(text: weightG > 0 ? weightG.toString() : ''),
        caloriesCtrl = TextEditingController(
            text: calories > 0 ? calories.toStringAsFixed(0) : ''),
        proteinCtrl = TextEditingController(
            text: proteinG > 0 ? proteinG.toStringAsFixed(1) : ''),
        fatCtrl = TextEditingController(
            text: fatG > 0 ? fatG.toStringAsFixed(1) : ''),
        carbCtrl = TextEditingController(
            text: carbohydrateG > 0 ? carbohydrateG.toStringAsFixed(1) : '');

  factory _EditableItem.fromJson(Map<String, dynamic> json) {
    return _EditableItem(
      foodName: json['food_name'] as String? ?? '',
      weightG: (json['weight_g'] as num? ?? 0).toDouble(),
      calories: (json['calories'] as num? ?? 0).toDouble(),
      proteinG: (json['protein_g'] as num? ?? 0).toDouble(),
      fatG: (json['fat_g'] as num? ?? 0).toDouble(),
      carbohydrateG: (json['carbohydrate_g'] as num? ?? 0).toDouble(),
      confidence: (json['confidence'] as num? ?? 1.0).toDouble(),
    );
  }

  factory _EditableItem.empty() => _EditableItem(
        foodName: '',
        weightG: 0,
        calories: 0,
      );

  FoodItemModel? toModel() {
    final name = nameCtrl.text.trim();
    final weight = double.tryParse(weightCtrl.text.trim());
    final calories = double.tryParse(caloriesCtrl.text.trim());
    if (name.isEmpty || weight == null) return null;
    return FoodItemModel(
      foodName: name,
      weightG: weight,
      calories: calories ?? 0,
      proteinG: double.tryParse(proteinCtrl.text.trim()) ?? 0,
      fatG: double.tryParse(fatCtrl.text.trim()) ?? 0,
      carbohydrateG: double.tryParse(carbCtrl.text.trim()) ?? 0,
      confidence: confidence,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    weightCtrl.dispose();
    caloriesCtrl.dispose();
    proteinCtrl.dispose();
    fatCtrl.dispose();
    carbCtrl.dispose();
  }
}

// ── 单条食物明细卡片 UI ──────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.item,
    required this.canRemove,
    required this.onRemove,
  });

  final _EditableItem item;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 名称 + 重量行
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: item.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '食物名称',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: item.weightCtrl,
                    decoration: const InputDecoration(
                      labelText: '重量(g)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: canRemove ? Colors.red : Colors.grey,
                  ),
                  onPressed: canRemove ? onRemove : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 营养数值行
            Row(
              children: [
                _NumField(ctrl: item.caloriesCtrl, label: '热量'),
                const SizedBox(width: 6),
                _NumField(ctrl: item.proteinCtrl, label: '蛋白质'),
                const SizedBox(width: 6),
                _NumField(ctrl: item.fatCtrl, label: '脂肪'),
                const SizedBox(width: 6),
                _NumField(ctrl: item.carbCtrl, label: '碳水'),
              ],
            ),
            // AI 置信度
            if (item.confidence < 1.0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'AI 置信度: ${(item.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.ctrl, required this.label});
  final TextEditingController ctrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
