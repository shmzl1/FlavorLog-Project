import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/fridge_controller.dart';
import '../../models/fridge_item_model.dart';

class CyberFridgePage extends StatelessWidget {
  const CyberFridgePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FridgeController>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('赛博冰箱'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.kitchen), text: '食材管理'),
              Tab(icon: Icon(Icons.auto_awesome), text: 'AI 食谱'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FridgeItemsTab(controller: controller),
            _RecipeTab(controller: controller),
          ],
        ),
        floatingActionButton: _AddItemFab(controller: controller),
      ),
    );
  }
}

// ── 食材列表 Tab ─────────────────────────────────────────────────────────────

class _FridgeItemsTab extends StatelessWidget {
  const _FridgeItemsTab({required this.controller});
  final FridgeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(controller.errorMessage.value,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: controller.loadItems,
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }
      if (controller.items.isEmpty) {
        return const Center(child: Text('冰箱是空的，点击右下角添加食材'));
      }

      // 即将过期提示
      final expiring = controller.expiringItems;
      return Column(
        children: [
          if (expiring.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${expiring.map((e) => e.name).join("、")} 即将过期，建议优先使用',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
              itemCount: controller.items.length,
              itemBuilder: (context, index) {
                return _FridgeItemCard(
                  item: controller.items[index],
                  controller: controller,
                );
              },
            ),
          ),
        ],
      );
    });
  }
}

// ── 单个食材卡片 ─────────────────────────────────────────────────────────────

class _FridgeItemCard extends StatelessWidget {
  const _FridgeItemCard({required this.item, required this.controller});
  final FridgeItemModel item;
  final FridgeController controller;

  static const Map<String, String> _categoryLabels = {
    'meat': '肉类',
    'vegetable': '蔬菜',
    'fruit': '水果',
    'dairy': '乳制品',
    'grain': '谷物',
    'seafood': '海鲜',
    'egg': '蛋类',
    'condiment': '调味品',
    'other': '其他',
  };

  static const Map<String, String> _locationLabels = {
    'freezer': '冷冻层',
    'fridge': '冷藏层',
    'room_temp': '常温',
  };

  @override
  Widget build(BuildContext context) {
    final categoryLabel =
        _categoryLabels[item.category] ?? (item.category ?? '');
    final locationLabel =
        _locationLabels[item.storageLocation] ?? (item.storageLocation ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isExpiringSoon
              ? Colors.orange.shade100
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.inventory_2_outlined,
            color: item.isExpiringSoon
                ? Colors.orange
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Text(item.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (item.isExpiringSoon) ...[
              const SizedBox(width: 6),
              const Chip(
                label: Text('临期', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.orangeAccent,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Text([
          if (categoryLabel.isNotEmpty) categoryLabel,
          '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}'
              '${item.unit ?? ''}',
          if (locationLabel.isNotEmpty) locationLabel,
          if (item.expireDate != null) '到期 ${item.expireDate}',
        ].join('  ·  ')),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(context),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除「${item.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final ok = await controller.deleteItem(item.id);
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

// ── AI 食谱 Tab ──────────────────────────────────────────────────────────────

class _RecipeTab extends StatefulWidget {
  const _RecipeTab({required this.controller});
  final FridgeController controller;

  @override
  State<_RecipeTab> createState() => _RecipeTabState();
}

class _RecipeTabState extends State<_RecipeTab> {
  String _target = 'high_protein';
  final _maxCalCtrl = TextEditingController(text: '600');

  static const List<DropdownMenuItem<String>> _targetItems = [
    DropdownMenuItem(value: 'high_protein', child: Text('高蛋白')),
    DropdownMenuItem(value: 'lose_fat', child: Text('减脂')),
    DropdownMenuItem(value: 'balanced', child: Text('均衡')),
    DropdownMenuItem(value: 'low_carb', child: Text('低碳水')),
  ];

  @override
  void dispose() {
    _maxCalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('生成食谱设置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _target,
            decoration: const InputDecoration(
              labelText: '目标',
              border: OutlineInputBorder(),
            ),
            items: _targetItems,
            onChanged: (v) => setState(() => _target = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _maxCalCtrl,
            decoration: const InputDecoration(
              labelText: '最大热量 (kcal)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.controller.isSubmitting.value
                    ? null
                    : _submitTask,
                icon: const Icon(Icons.auto_awesome),
                label: widget.controller.isSubmitting.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('生成食谱'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _RecipeResultView(controller: widget.controller),
        ],
      ),
    );
  }

  Future<void> _submitTask() async {
    final maxCal = int.tryParse(_maxCalCtrl.text.trim());
    final ok = await widget.controller.submitRecipeTask(
      target: _target,
      maxCalories: maxCal,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage.value)),
      );
    }
  }
}

class _RecipeResultView extends StatelessWidget {
  const _RecipeResultView({required this.controller});
  final FridgeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = controller.recipeTaskStatus.value;
      if (status.isEmpty) return const SizedBox.shrink();

      if (status == 'pending' || status == 'running') {
        return Column(
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('任务处理中（$status）'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: controller.pollRecipeTask,
                  child: const Text('刷新'),
                ),
              ],
            ),
          ],
        );
      }

      if (status == 'failed') {
        return const Text('食谱生成失败，请重试',
            style: TextStyle(color: Colors.red));
      }

      final result = controller.recipeResult.value;
      if (result == null) return const SizedBox.shrink();

      final title = result['title'] as String? ?? '';
      final description = result['description'] as String? ?? '';
      final ingredients =
          (result['ingredients'] as List<dynamic>? ?? []);
      final steps = (result['steps'] as List<dynamic>? ?? []);
      final nutrition =
          result['nutrition'] as Map<String, dynamic>? ?? {};

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(description,
                  style: TextStyle(color: Colors.grey.shade600)),
              const Divider(height: 20),
              const Text('食材清单',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...ingredients.map((e) {
                final m = e as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Text(
                      '· ${m['name']}  ${m['amount']}'),
                );
              }),
              const Divider(height: 20),
              const Text('烹饪步骤',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...steps.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('${e.key + 1}. ${e.value}'),
                    ),
                  ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NutritionChip(
                    label: '热量',
                    value: '${nutrition['calories'] ?? '-'} kcal',
                  ),
                  _NutritionChip(
                    label: '蛋白质',
                    value: '${nutrition['protein_g'] ?? '-'} g',
                  ),
                  _NutritionChip(
                    label: '脂肪',
                    value: '${nutrition['fat_g'] ?? '-'} g',
                  ),
                  _NutritionChip(
                    label: '碳水',
                    value: '${nutrition['carbohydrate_g'] ?? '-'} g',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _NutritionChip extends StatelessWidget {
  const _NutritionChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ── 添加食材 FAB ─────────────────────────────────────────────────────────────

class _AddItemFab extends StatelessWidget {
  const _AddItemFab({required this.controller});
  final FridgeController controller;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AddItemSheet(controller: controller),
      ),
      icon: const Icon(Icons.add),
      label: const Text('添加食材'),
    );
  }
}

// ── 添加食材底部表单 ──────────────────────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({required this.controller});
  final FridgeController controller;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _weightCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();
  String? _category;
  String? _unit = 'piece';
  String? _storageLocation = 'fridge';
  DateTime? _expireDate;

  static const List<DropdownMenuItem<String?>> _categoryItems = [
    DropdownMenuItem(value: null, child: Text('不分类')),
    DropdownMenuItem(value: 'meat', child: Text('肉类')),
    DropdownMenuItem(value: 'vegetable', child: Text('蔬菜')),
    DropdownMenuItem(value: 'fruit', child: Text('水果')),
    DropdownMenuItem(value: 'dairy', child: Text('乳制品')),
    DropdownMenuItem(value: 'grain', child: Text('谷物')),
    DropdownMenuItem(value: 'seafood', child: Text('海鲜')),
    DropdownMenuItem(value: 'egg', child: Text('蛋类')),
    DropdownMenuItem(value: 'condiment', child: Text('调味品')),
    DropdownMenuItem(value: 'other', child: Text('其他')),
  ];

  static const List<DropdownMenuItem<String?>> _unitItems = [
    DropdownMenuItem(value: 'piece', child: Text('个/块')),
    DropdownMenuItem(value: 'g', child: Text('克(g)')),
    DropdownMenuItem(value: 'kg', child: Text('千克(kg)')),
    DropdownMenuItem(value: 'ml', child: Text('毫升(ml)')),
    DropdownMenuItem(value: 'L', child: Text('升(L)')),
    DropdownMenuItem(value: 'bag', child: Text('袋')),
    DropdownMenuItem(value: 'box', child: Text('盒')),
  ];

  static const List<DropdownMenuItem<String?>> _locationItems = [
    DropdownMenuItem(value: 'fridge', child: Text('冷藏层')),
    DropdownMenuItem(value: 'freezer', child: Text('冷冻层')),
    DropdownMenuItem(value: 'room_temp', child: Text('常温')),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _weightCtrl.dispose();
    _remarkCtrl.dispose();
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
                      child: Text('添加食材',
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
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '食材名称*',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '请填写食材名称' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantityCtrl,
                        decoration: const InputDecoration(
                          labelText: '数量*',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            double.tryParse(v ?? '') == null ? '请填写数量' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _unit,
                        decoration: const InputDecoration(
                          labelText: '单位',
                          border: OutlineInputBorder(),
                        ),
                        items: _unitItems,
                        onChanged: (v) => setState(() => _unit = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: '分类',
                          border: OutlineInputBorder(),
                        ),
                        items: _categoryItems,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _storageLocation,
                        decoration: const InputDecoration(
                          labelText: '存储位置',
                          border: OutlineInputBorder(),
                        ),
                        items: _locationItems,
                        onChanged: (v) =>
                            setState(() => _storageLocation = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightCtrl,
                        decoration: const InputDecoration(
                          labelText: '重量(g，可选)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _expireDate == null
                              ? '过期日期'
                              : '${_expireDate!.year}-${_expireDate!.month.toString().padLeft(2, '0')}-${_expireDate!.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(Icons.event),
                        onTap: _pickExpireDate,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _remarkCtrl,
                  decoration: const InputDecoration(
                    labelText: '备注（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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

  Future<void> _pickExpireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expireDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final expireStr = _expireDate == null
        ? null
        : '${_expireDate!.year}-${_expireDate!.month.toString().padLeft(2, '0')}-${_expireDate!.day.toString().padLeft(2, '0')}';
    final ok = await widget.controller.createItem(
      name: _nameCtrl.text.trim(),
      category: _category,
      quantity: double.parse(_quantityCtrl.text.trim()),
      unit: _unit,
      weightG: double.tryParse(_weightCtrl.text.trim()),
      expireDate: expireStr,
      storageLocation: _storageLocation,
      remark: _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('食材已添加')),
      );
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage.value)),
      );
    }
  }
}
