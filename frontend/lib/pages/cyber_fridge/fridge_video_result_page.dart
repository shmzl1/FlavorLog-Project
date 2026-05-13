import 'package:flutter/material.dart';

import '../../models/fridge_item_model.dart';
import '../../services/api/fridge_service.dart';

/// 冰箱视频扫描结果页
/// 展示 AI 扫描并已保存的食材列表，用户可修改名称/分类或删除
class FridgeVideoResultPage extends StatefulWidget {
  final List<FridgeItemModel> scannedItems;

  const FridgeVideoResultPage({super.key, required this.scannedItems});

  @override
  State<FridgeVideoResultPage> createState() => _FridgeVideoResultPageState();
}

class _FridgeVideoResultPageState extends State<FridgeVideoResultPage> {
  late List<_EditableItemState> _itemStates;
  bool _isSaving = false;

  static const Map<String?, String> _categoryLabels = {
    null: '不分类',
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

  static final List<DropdownMenuItem<String?>> _categoryItems =
      _categoryLabels.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList();

  @override
  void initState() {
    super.initState();
    _itemStates =
        widget.scannedItems.map(_EditableItemState.fromModel).toList();
  }

  @override
  void dispose() {
    for (final s in _itemStates) {
      s.dispose();
    }
    super.dispose();
  }

  // ── 删除单个食材（调用 API 删除已保存的记录）──────────────
  Future<void> _deleteItem(int index) async {
    final item = _itemStates[index];
    setState(() => item.isDeleting = true);
    try {
      await FridgeService.instance.deleteItem(item.id);
      setState(() => _itemStates.removeAt(index));
    } catch (e) {
      setState(() => item.isDeleting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }

  // ── 保存所有已修改的名称/分类（批量 update）─────────────────
  Future<void> _saveEdits() async {
    setState(() => _isSaving = true);
    for (final s in _itemStates) {
      if (!s.isDirty) continue;
      try {
        final updated = FridgeItemModel(
          id: s.id,
          userId: s.userId,
          name: s.nameCtrl.text.trim().isEmpty
              ? s.originalName
              : s.nameCtrl.text.trim(),
          category: s.category,
          quantity: s.quantity,
          unit: s.unit,
          weightG: s.weightG,
          expireDate: s.expireDate,
          storageLocation: s.storageLocation,
          remark: s.remark,
          createdAt: s.createdAt,
        );
        await FridgeService.instance.updateItem(s.id, updated);
      } catch (_) {
        // 忽略单条更新失败，不影响整体完成
      }
    }
    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描结果'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEdits,
            child: const Text('完成',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _itemStates.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.kitchen_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('所有识别到的食材已删除',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                // 顶部提示横幅
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI 已扫描到 ${_itemStates.length} 种食材并录入冰箱，'
                          '请修正名称/分类，或删除识别错误的项目',
                          style: TextStyle(
                              color: Colors.blue.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                ..._itemStates.asMap().entries.map(
                      (e) => _ScannedItemCard(
                        key: ValueKey(e.value.id),
                        itemState: e.value,
                        categoryItems: _categoryItems,
                        onDelete: () => _deleteItem(e.key),
                      ),
                    ),
              ],
            ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _saveEdits,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check),
          label: const Text('完成'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    );
  }
}

// ── 可编辑的食材状态 ──────────────────────────────────────────────────────────

class _EditableItemState {
  final int id;
  final int userId;
  final String originalName;
  final TextEditingController nameCtrl;
  String? category;
  final double quantity;
  final String? unit;
  final double? weightG;
  final String? expireDate;
  final String? storageLocation;
  final String? remark;
  final String createdAt;
  bool isDeleting = false;

  _EditableItemState({
    required this.id,
    required this.userId,
    required this.originalName,
    required this.nameCtrl,
    this.category,
    required this.quantity,
    this.unit,
    this.weightG,
    this.expireDate,
    this.storageLocation,
    this.remark,
    required this.createdAt,
  });

  factory _EditableItemState.fromModel(FridgeItemModel m) {
    return _EditableItemState(
      id: m.id,
      userId: m.userId,
      originalName: m.name,
      nameCtrl: TextEditingController(text: m.name),
      category: m.category,
      quantity: m.quantity,
      unit: m.unit,
      weightG: m.weightG,
      expireDate: m.expireDate,
      storageLocation: m.storageLocation,
      remark: m.remark,
      createdAt: m.createdAt,
    );
  }

  /// 当前内容是否与原始值不同（用于决定是否发起 update 请求）
  bool get isDirty {
    return nameCtrl.text.trim() != originalName || category != null;
  }

  void dispose() => nameCtrl.dispose();
}

// ── 单个食材卡片 ──────────────────────────────────────────────────────────────

class _ScannedItemCard extends StatefulWidget {
  const _ScannedItemCard({
    super.key,
    required this.itemState,
    required this.categoryItems,
    required this.onDelete,
  });

  final _EditableItemState itemState;
  final List<DropdownMenuItem<String?>> categoryItems;
  final VoidCallback onDelete;

  @override
  State<_ScannedItemCard> createState() => _ScannedItemCardState();
}

class _ScannedItemCardState extends State<_ScannedItemCard> {
  @override
  Widget build(BuildContext context) {
    final s = widget.itemState;
    if (s.isDeleting) {
      return const Card(
        margin: EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text('删除中...'),
          trailing: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 名称行
            Row(
              children: [
                const Icon(Icons.kitchen, size: 20, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: s.nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '食材名称',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: widget.onDelete,
                  tooltip: '删除此食材',
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 分类行
            DropdownButtonFormField<String?>(
              value: s.category,
              decoration: const InputDecoration(
                labelText: '分类',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: widget.categoryItems,
              onChanged: (v) => setState(() => s.category = v),
            ),
            // 数量/单位提示
            if (s.quantity > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '数量：${s.quantity.toStringAsFixed(s.quantity == s.quantity.roundToDouble() ? 0 : 1)}'
                    '${s.unit != null ? ' ${s.unit}' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
