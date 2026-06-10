import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/food_record_controller.dart';
import '../../models/food_record_model.dart';

/// 【类说明：视频录入 AI 识别结果确认控制舱】
/// 作用：
/// 用户使用 AI 智慧录视频后，在此对大模型智能识别提取出的饮食记录草稿进行最终审查、细化微调与入库。
/// 
/// 视觉设计：
/// 1. 采用 Bento 圆角卡牌流光框架承载识别项，极具现代 AI 未来感。
/// 2. 弃用死板矩形框，全部使用高弧度圆润胶囊交互组件，极大提升手指触击舒适度。
/// 3. 置信度评分根据数值区间动态染色（高置信度绿，中置信度黄，低置信度红），展现极高专业度。
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
    DropdownMenuItem(value: 'breakfast', child: Text('🌅 早餐', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'lunch', child: Text('☀️ 午餐', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'dinner', child: Text('🌙 晚餐', style: TextStyle(fontWeight: FontWeight.bold))),
    DropdownMenuItem(value: 'snack', child: Text('🍎 加餐', style: TextStyle(fontWeight: FontWeight.bold))),
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
      backgroundColor: const Color(0xFFF8F9FA), // 全局统一微灰底色，悬浮卡片感更好
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '确认食物信息',
          style: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
        children: [
          // 1. AI 智能高能提示标牌
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE3FCEC), Color(0xFFD1FADF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA3E9B9).withOpacity(0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF20BF6B).withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF20BF6B), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI 智能识别完成！共锁定 ${_items.length} 种食物，请在下方核准或精细修正您的进食信息：',
                    style: const TextStyle(color: Color(0xFF1A5336), fontSize: 12.5, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Bento 设置控制舱
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1C1C1E).withOpacity(0.02),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(color: const Color(0xFFEFEFF4), width: 1),
            ),
            child: Column(
              children: [
                // 餐次选择
                DropdownButtonFormField<String>(
                  value: _mealType,
                  decoration: InputDecoration(
                    labelText: '餐次',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF6B35), size: 18),
                  ),
                  items: _mealItems,
                  onChanged: (v) => setState(() => _mealType = v!),
                ),
                const SizedBox(height: 14),

                // 时间选择
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Text(
                    '记录时间：${_recordTime.hour.toString().padLeft(2, '0')}:${_recordTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  trailing: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF5AC8FA), size: 20),
                  onTap: _pickTime,
                  tileColor: const Color(0xFFF2F2F7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                const SizedBox(height: 14),

                // 备注
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: '餐单细节备注（可选）',
                    labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13, fontWeight: FontWeight.bold),
                    hintText: '例：少油少盐、这餐吃得很饱...',
                    hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF4CD964), size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. 食物列表头部
          Row(
            children: [
              const Expanded(
                child: Text(
                  '识别到的食物明细',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1C1C1E)),
                ),
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFFF6B35)),
                label: const Text('手动补齐单项', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 4. 食物卡片列表
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

      // 5. 底部高光渐变大按钮舱
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFF2F2F7), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Obx(
          () => Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: controller.isSubmitting.value
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFF8E53), Color(0xFFFF6B35)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: controller.isSubmitting.value ? null : [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: controller.isSubmitting.value ? null : () => _save(controller),
                child: Center(
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '确认无误，保存此餐数据',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                ),
              ),
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
      Get.snackbar(
        '保存失败',
        '请至少保留一种食物信息哦',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(Icons.warning_rounded, color: Color(0xFFFFCC00)),
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
      Get.snackbar(
        '保存成功 🎉',
        '饮食记录已成功确认入库！',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF20BF6B)),
      );
    } else {
      Get.snackbar(
        '保存失败',
        controller.errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1C1C1E).withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFFF4757)),
      );
    }
  }
}

// ── 单条食物明细数据桥梁 ────────────────────────────────────────────────────

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

  Color _getConfidenceColor(double conf) {
    if (conf >= 0.85) return const Color(0xFF20BF6B); // 高置信度 绿色
    if (conf >= 0.6) return const Color(0xFFFFCC00);  // 中置信度 黄色
    return const Color(0xFFFF4757);                  // 低置信度 红色
  }

  @override
  Widget build(BuildContext context) {
    final confColor = _getConfidenceColor(item.confidence);
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C1E).withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: const Color(0xFFEFEFF4), width: 1),
      ),
      child: Column(
        children: [
          // 名称 + 重量行
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: item.nameCtrl,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration('食物名称', Icons.restaurant_menu_rounded),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: item.weightCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration('重量(g)', Icons.scale_rounded),
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFFF4757), size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 营养数值行
          Row(
            children: [
              _NumField(ctrl: item.caloriesCtrl, label: '热量 (kcal)'),
              const SizedBox(width: 6),
              _NumField(ctrl: item.proteinCtrl, label: '蛋白(g)'),
              const SizedBox(width: 6),
              _NumField(ctrl: item.fatCtrl, label: '脂肪(g)'),
              const SizedBox(width: 6),
              _NumField(ctrl: item.carbCtrl, label: '碳水(g)'),
            ],
          ),
          // AI 置信度高级微章
          if (item.confidence < 1.0) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: confColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: confColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI 置信度: ${(item.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 10, color: confColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 9, fontWeight: FontWeight.bold),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFFF6B35))),
        ),
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
