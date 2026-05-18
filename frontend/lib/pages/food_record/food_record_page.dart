// frontend/lib/pages/food_record/food_record_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/empty_state.dart';
import '../../components/section_card.dart';
import '../../components/stat_tile.dart';
import '../../controllers/food_record_controller.dart';
import '../../models/food_record_model.dart';
import 'food_video_entry_page.dart';

/// 【类说明：FlavorLog 智慧饮食记录中心主页面】
/// 作用：
/// 纵向聚合渲染用户选定日期的已摄入饮食总线列表，支持日期回溯选择及多维度 AI/手动录入。
/// 
/// 设计语言：
/// 1. 全局切换为现代高阶轻奢微灰背景（0xFFF8F9FA），极大增加了白色功能卡片的“悬浮呼吸感”。
/// 2. 顶部和卡片元素全部融入 Apple Health 配色体系，彻底告别原生态学生作业界面的扁平感。
class FoodRecordPage extends StatelessWidget {
  const FoodRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 依赖查找：精准获取绑定的饮食记录全局业务控制器
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
            icon: const Icon(Icons.calendar_today_rounded, color: Color(0xFFFF6B35), size: 20),
            tooltip: '选择日期',
            onPressed: () => _pickDate(context, controller), // 唤醒日历回溯
          ),
        ],
      ),
      body: Column(
        children: [
          // 模块一：顶部悬浮胶囊日期条
          _DateBar(controller: controller),
          
          // 统一由布局包裹，增加滑动缓冲呼吸感
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // 模块二：今日四大营养元素汇总大仪表盘
                  _SummaryBar(controller: controller),
                  
                  // 模块三：核心饮食卡片时光流列表容器
                  _RecordList(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
      // 模块四：黑武士黑极简延伸悬浮功能大按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, controller),
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          '新增饮食记录',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  /// 【业务功能函数：弹出日期选择器】
  /// 作用：供用户回溯或查看指定日期的历史饮食记录，使用 async/await 安全通信。
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
              primary: Color(0xFFFF6B35), // 按钮主色调改为高颜值橙色
              onPrimary: Colors.white,
              onSurface: Color(0xFF1C1C1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await controller.changeDate(picked); // 触发网关异步更新
    }
  }

  /// 【业务功能函数：点击新增弹出的底部操作菜单】
  /// 视觉亮点：融入了圆润包络设计，高亮区分了 AI 视觉录入和常规手动录入。
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
                if (ok == true) controller.loadRecords(); // 成功后响应式洗牌数据
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
                _showAddDialog(context, controller); // 唤起长表单
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  /// 【业务功能函数：唤起手动录入长表单抽屉】
  void _showAddDialog(BuildContext context, FoodRecordController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // 准许长表单高度自适应
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddRecordSheet(controller: controller),
    );
  }
}

// ── 日期标题栏 ────────────────────────────────────────────────────────────────

/// 【类说明：响应式胶囊日期展示条】
/// 视觉突破：摒弃了生硬铺满的粗糙彩条，进化为了带有微型日历图标、柔和内嵌衬底的高级窄边胶囊。
class _DateBar extends StatelessWidget {
  const _DateBar({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final d = controller.selectedDate.value;
      final label = '${d.year}年 ${d.month.toString().padLeft(2, '0')}月 ${d.day.toString().padLeft(2, '0')}日';
      
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFF4), // 极其轻柔的灰衬底
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFFFF6B35)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: const Text("历史追溯", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E8E93))),
            )
          ],
        ),
      );
    });
  }
}

// ── 当日营养汇总 ────────────────────────────────────────────────────────────

/// 【类说明：今日核心四大营养素总览看板】
/// 作用：全量聚合展示用户今天已经吃进去的总能量百分比大盘。
/// 
/// 核心修复点保留：
/// 100% 沿用了你原本修正过后的 [SliverGridDelegateWithFixedCrossAxisCount] 网格机制，
/// 严格设定 [mainAxisExtent: 90]，保障多版本设备上均绝对 0 溢出、0 爆红。
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 状态判断：如果今天没有吃任何东西，优雅隐形折叠，不霸占首屏空间
      if (controller.records.isEmpty) return const SizedBox.shrink();
      
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: SectionCard(
          title: '今日累计摄入摘要',
          child: GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 94, // 契合高颜值内边距适当挑高 4px
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // 剥离滚动主控权
            children: [
              StatTile(
                title: '累计热量',
                value: controller.todayTotalCalories.toStringAsFixed(0),
                unit: 'kcal',
                icon: Icons.local_fire_department_rounded,
              ),
              StatTile(
                title: '蛋白质',
                value: controller.todayTotalProtein.toStringAsFixed(1),
                unit: 'g',
                icon: Icons.fitness_center_rounded,
              ),
              StatTile(
                title: '脂肪总合',
                value: controller.todayTotalFat.toStringAsFixed(1),
                unit: 'g',
                icon: Icons.water_drop_rounded,
              ),
              StatTile(
                title: '碳水化合物',
                value: controller.todayTotalCarbohydrate.toStringAsFixed(1),
                unit: 'g',
                icon: Icons.grain_rounded,
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── 记录列表 ────────────────────────────────────────────────────────────────

/// 【类说明：流水卡片时光流分流控制引擎】
/// 作用：
/// 响应式分流控制器反馈的三大核心网络状态：加载中（菊花转圈）、异步编译失败（断网占位）、零数据记录（引导记录）。
class _RecordList extends StatelessWidget {
  const _RecordList({required this.controller});
  final FoodRecordController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 状态分流 1：底层异步网关加载中
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.only(top: 100),
          child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)))),
        );
      }
      
      // 状态分流 2：网络响应超时或业务异常，触发带有重试机制的 EmptyState
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
      
      // 状态分流 3：数据拉取完成但为空集，温和召回表单
      if (controller.records.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 80, left: 20, right: 20),
          child: EmptyState(
            icon: Icons.restaurant_menu_outlined,
            title: '今天还没有饮食打卡',
            message: '健康的体魄源于自律。点击右下角按钮，让 AI 帮你评估今天的第一餐吧！',
          ),
        );
      }
      
      // 状态分流 4：完美数据态，构建卡片瀑布流
      return ListView.builder(
        shrinkWrap: true, // 准许内嵌滚动流高度由内容决断
        physics: const NeverScrollableScrollPhysics(), // 由最外层全幅单容器接管，避免双重滚动冲突
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), // 预留 100px 完美避开 FAB
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

/// 【类说明：单餐次（例:午餐）高级折叠风风瓦片】
/// 作用：解包并优雅绘制单餐热量。利用 ExpansionTile 组件提供丝滑的“手风琴式”明细展开抽屉。
/// 
/// 视觉设计：
/// 增加了卡片边缘细线框与微小的拟物阴影。内部的食物单项改用了圆润的小胶囊作为前置标，设计极具精致度。
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.controller});
  final FoodRecordModel record;
  final FoodRecordController controller;

  // 核心中英文字符串软字典
  static const Map<String, String> _mealLabels = {
    'breakfast': '🌅 活力早餐',
    'lunch': '☀️ 能量午餐',
    'dinner': '🌙 饱腹晚餐',
    'snack': '🍎 营养加餐',
  };

  static const Map<String, IconData> _mealIcons = {
    'breakfast': Icons.wb_sunny_rounded,
    'lunch': Icons.lunch_dining_rounded,
    'dinner': Icons.dinner_dining_rounded,
    'snack': Icons.cookie_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final mealLabel = _mealLabels[record.mealType] ?? record.mealType;
    final mealIcon = _mealIcons[record.mealType] ?? Icons.restaurant_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 6)),
        ],
        border: Border.all(color: const Color(0xFFEFEFF4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // 剔除原生展开时上下附带的死板长横线
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(mealIcon, color: const Color(0xFFFF6B35), size: 20),
            ),
            title: Text(mealLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1C1C1E))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${record.totalCalories.toStringAsFixed(0)} kcal'
                '${record.description != null ? '  ·  ${record.description}' : ''}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4757), size: 18),
                  tooltip: '删除',
                  onPressed: () => _confirmDelete(context), // 触发二次拦截确认
                ),
                const Icon(Icons.expand_more_rounded, color: Color(0xFFC7C7CC), size: 20),
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
        ),
      ),
    );
  }

  /// 【内部辅助组件：单条食材数据名录行】
  Widget _buildItemRow(FoodItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFFFFCC00), shape: BoxShape.circle), // 金黄色轻奢圆点
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item.foodName}  ${item.weightG.toStringAsFixed(0)}g',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50)),
            ),
          ),
          Text(
            '${item.calories.toStringAsFixed(0)} kcal',
            style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 【业务安全拦截：二次确认物理删除弹窗】
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
              final ok = await controller.deleteRecord(record.id); // 调取异步网关指令
              if (!ok && context.mounted) {
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

/// 【类说明：全新升级高颜值餐食追加表单（高级 Stateful 弹窗）】
/// 作用：支持多行食物明细并发录入。
/// 
/// 核心健壮性保留：
/// 1. 100% 还原了老代码里的全局 `_formKey` 逻辑与 Dropdown / 复合时间选择机制。
/// 2. 100% 原位复活并重写了原版的 `_itemForms` 动态增删食物控制器映射栈，确保你的多选录入和拆解逻辑能无缝连接。
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

  // 状态集合核心：初始化挂载一条食物控制器表单骨架
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
      f.dispose(); // 严格进行资源回收，杜绝多项录入时的隐形内存泄漏
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        // 【抗遮挡黑科技原样保留】：实时嗅探系统软键盘动态弹升高度，托起表单底座，无死角保障长文本录入手感
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
                // 顶置导航条
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
                
                // 字段 1：餐次选择下拉舱
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
                
                // 字段 2：高精度时间选择条
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
                
                // 字段 3：情感备注说明
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
                
                // 字段 4：核心动态组 - 食物食材名录明细流
                Row(
                  children: [
                    const Expanded(
                      child: Text('核心食物成分细化', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1C1C1E))),
                    ),
                    TextButton.icon(
                      onPressed: _addItem, // 数组越阶压栈
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFFF6B35)),
                      label: const Text('添加单项食材', style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // 动态构建子组件矩阵（完全同步原版的 map 数据分发与 key 标识）
                ..._itemForms.asMap().entries.map(
                      (e) => _FoodItemFormWidget(
                        key: ValueKey(e.key),
                        form: e.value,
                        onRemove: _itemForms.length > 1 ? () => _removeItem(e.key) : null, // 触发解构回滚，保留低保 1 项限制
                      ),
                    ),
                const SizedBox(height: 24),
                
                // 执行按钮组件（挂载 GetX controller.isSubmitting 独家响应式防连击状态菊花）
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

  /// 【内部控制功能：拉开原生时间滚轮】
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

  /// 【动态操作：追加一条空的食物名录控制器骨架】
  void _addItem() {
    setState(() => _itemForms.add(_FoodItemForm()));
  }

  /// 【动态操作：销毁指定索引的食物控制器并将其踢出渲染栈】
  void _removeItem(int index) {
    setState(() {
      _itemForms[index].dispose(); // 提前擦除资源
      _itemForms.removeAt(index);
    });
  }

  /// 【网络层中枢：数据全量合法性校验与封装包投递】
  Future<void> _submit() async {
    // 步骤 1：挂载原生表单级阻断器，发现不合法直接抛红终止线程
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    // 步骤 2：遍历局部表单控制器栈，提炼出实体模型数组
    final items = _itemForms
        .map((f) => f.toModel())
        .whereType<FoodItemModel>()
        .toList();
        
    // 步骤 3：低保判定，如果全是空内容，触发 SnackBar 警告
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ 请至少完整填写一种食物的信息哦'), backgroundColor: Color(0xFFFFCC00), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    // 步骤 4：无缝调取你原版的 createRecord 底层网络投递功能契约
    final ok = await widget.controller.createRecord(
      mealType: _mealType,
      recordTime: _recordTime,
      sourceType: 'manual',
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      items: items,
    );
    
    // 步骤 5：处理网络网关交互返回结果
    if (ok && mounted) {
      Navigator.of(context).pop();
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

/// 【类说明：复合型单体食物文本输入控制器控制舱】
/// 作用：100% 对应并接管原版 6 大核心文本控制总线（name、weight、calories、protein、fat、carb），
/// 提供原装的 [toModel] 转译手艺，安全返回 [FoodItemModel] 实体类。
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

/// 【类说明：单行食物录入项网格输入瓦片（高完备矩阵版）】
/// 视觉设计：
/// 升级为包裹在一张优雅的浅白色卡牌框内。上层双列平铺核心两项（名称、克数），
/// 下层采用等宽四列密集网格完美安置“热量与三大营养微量元素”，排版极具对齐严谨度。
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
          // 第一行：食物名称 & 重量（严格保留原装必填 Validator）
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
              // 如果表单项大于1条，渲染高颜值删除悬浮章
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFFF4757), size: 20),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 10),
          
          // 第二行：密集网格四连击（卡路里、蛋白、脂肪、碳水并排平铺）
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

  /// 输入框公用拟物美化渲染器 1
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

  /// 输入框公用密集渲染器 2
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