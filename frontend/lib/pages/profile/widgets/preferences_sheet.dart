import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/profile_controller.dart';

class PreferencesSheet extends StatefulWidget {
  const PreferencesSheet({super.key});

  @override
  State<PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<PreferencesSheet> {
  late final ProfileController _profileController;
  late final TextEditingController preferenceController;
  late final TextEditingController allergenController;
  late final List<String> tempPreferences;
  late final List<String> tempAllergies;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileController = Get.find<ProfileController>();
    preferenceController = TextEditingController();
    allergenController = TextEditingController();
    tempPreferences = List<String>.from(_profileController.preferenceTags);
    tempAllergies = List<String>.from(_profileController.allergyTags);
  }

  @override
  void dispose() {
    preferenceController.dispose();
    allergenController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (_isSaving) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSaving = true;
    });

    final ok = await _profileController.updateProfile(
      newDiet: List<String>.from(tempPreferences),
      newAllergens: List<String>.from(tempAllergies),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (ok) {
      Navigator.of(context).pop();
      Get.snackbar(
        '设置已更新',
        '饮食偏好和过敏原已保存',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF20BF6B),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        '更新失败',
        '请稍后再试',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFF4757),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
    }
  }

  void _addPreference() {
    final text = preferenceController.text.trim();
    if (text.isEmpty || tempPreferences.contains(text)) return;

    setState(() {
      tempPreferences.add(text);
    });
    preferenceController.clear();
  }

  void _addAllergen() {
    final text = allergenController.text.trim();
    if (text.isEmpty || tempAllergies.contains(text)) return;

    setState(() {
      tempAllergies.add(text);
    });
    allergenController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.86,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '饮食偏好和过敏原',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93)),
                      onPressed: _isSaving
                          ? null
                          : () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Navigator.of(context).pop();
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreferenceSection(),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Color(0xFFE5E5EA)),
                        const SizedBox(height: 20),
                        _buildAllergenSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8E8E93),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE5E5EA)),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildSaveButton(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('🥗', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text(
              '饮食偏好',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tempPreferences.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '暂无饮食偏好标签',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tempPreferences.map((tag) {
              return _buildEditingTag(
                tag,
                const Color(0xFF20BF6B),
                () {
                  setState(() {
                    tempPreferences.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        _buildMiniInputField(
          controller: preferenceController,
          hint: '输入自定义偏好，如：抗糖',
          activeColor: const Color(0xFF20BF6B),
          onAdd: _addPreference,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['高蛋白', '低碳/生酮', '轻食减脂', '抗糖/低糖', '清淡饮食', '少盐少油'].map((rec) {
            final selected = tempPreferences.contains(rec);
            return _buildSelectableChip(
              rec,
              selected,
              const Color(0xFF20BF6B),
              () {
                setState(() {
                  if (selected) {
                    tempPreferences.remove(rec);
                  } else {
                    tempPreferences.add(rec);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAllergenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text(
              '需避开的过敏原 / 食物',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tempAllergies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '暂无需要避开的食物',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tempAllergies.map((tag) {
              return _buildEditingTag(
                tag,
                const Color(0xFFFF4757),
                () {
                  setState(() {
                    tempAllergies.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        _buildMiniInputField(
          controller: allergenController,
          hint: '输入需避开的过敏原，如：海鲜',
          activeColor: const Color(0xFFFF4757),
          onAdd: _addAllergen,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: ['花生', '海鲜', '牛奶/乳糖', '小麦/麸质', '大豆', '坚果', '鸡蛋'].map((rec) {
            final selected = tempAllergies.contains(rec);
            return _buildSelectableChip(
              rec,
              selected,
              const Color(0xFFFF4757),
              () {
                setState(() {
                  if (selected) {
                    tempAllergies.remove(rec);
                  } else {
                    tempAllergies.add(rec);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A5C), Color(0xFFFF6B35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSaving ? null : _savePreferences,
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditingTag(String label, Color color, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: color,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFE5E5EA),
            width: 1,
          ),
          boxShadow: selected
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF1C1C1E).withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? color : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniInputField({
    required TextEditingController controller,
    required String hint,
    required Color activeColor,
    required VoidCallback onAdd,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C1C1E).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFC7C7CC),
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
              enabled: !_isSaving,
              onSubmitted: (_) => onAdd(),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isSaving ? null : onAdd,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.add_rounded, color: activeColor, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
