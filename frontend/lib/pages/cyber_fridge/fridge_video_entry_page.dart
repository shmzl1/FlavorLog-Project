import 'dart:async';
import 'dart:math' show sin;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../models/fridge_item_model.dart';
import '../../services/api/fridge_service.dart';
import '../../utils/shelf_life_utils.dart';

/// 冰箱 - 视频扫描录入页
/// 用户录制一段视频展示食材，AI 自动检测并录入冰箱
class FridgeVideoEntryPage extends StatefulWidget {
  const FridgeVideoEntryPage({super.key});

  @override
  State<FridgeVideoEntryPage> createState() => _FridgeVideoEntryPageState();
}

class _FridgeVideoEntryPageState extends State<FridgeVideoEntryPage>
    with TickerProviderStateMixin {
  // ── 相机 ──────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraReady = false;

  // ── 录制状态 ──────────────────────────────────────────────
  bool _isRecording = false;
  bool _isUploading = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;

  // ── 上传进度 ──────────────────────────────────────────────
  String _uploadStatus = '';
  double _uploadProgress = 0.0;

  // ── 脉冲动画 ──────────────────────────────────────────────
  late AnimationController _pulseCtrl;

  // ── 声纹波形 ──────────────────────────────────────────────
  final List<double> _waveHeights = List.generate(20, (_) => 4.0);
  Timer? _waveTimer;
  int _wavePhase = 0;

  static const int _maxRecordSeconds = 60;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('相机初始化失败: $e');
    }
  }

  // ── 开始录制 ──────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (_cameraController == null || !_isCameraReady) return;
    try {
      await _cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _recordSeconds++);
        if (_recordSeconds >= _maxRecordSeconds) _stopRecording();
      });
      _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
        if (!mounted) return;
        setState(() {
          _wavePhase = (_wavePhase + 1) % 360;
          for (int i = 0; i < _waveHeights.length; i++) {
            final angle =
                (i / _waveHeights.length + _wavePhase / 360.0) * 2 * 3.14159;
            _waveHeights[i] =
                4.0 + 22.0 * ((1 + sin(angle * 3.7 + i * 0.8)) / 2);
          }
        });
      });
    } catch (e) {
      _showError('录制失败：$e');
    }
  }

  // ── 停止录制 ──────────────────────────────────────────────
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    try {
      final file = await _cameraController!.stopVideoRecording();
      setState(() => _isRecording = false);
      await _uploadVideo(file.path);
    } catch (e) {
      setState(() => _isRecording = false);
      _showError('录制终止：$e');
    }
  }

  // ── 上传并扫描 ────────────────────────────────────────────
  Future<void> _uploadVideo(String path) async {
    setState(() {
      _isUploading = true;
      _uploadStatus = '上传视频中...';
      _uploadProgress = 0.1;
    });
    try {
      setState(() {
        _uploadStatus = 'AI 识别食材中...';
        _uploadProgress = 0.4;
      });

      // ① 先用 preview=true：只识别，不写库
      final resp = await FridgeService.instance.recognizeFromVideo(path);

      setState(() {
        _uploadProgress = 0.85;
        _uploadStatus = '识别完成，等待确认...';
        _isUploading = false;
      });

      if (!resp.isSuccess || resp.data == null || resp.data!.isEmpty) {
        final msg = (resp.message.isNotEmpty)
            ? resp.message
            : 'AI 无法识别食材，请对准食物重新录制';
        _showRecognitionFailed(msg);
        return;
      }

      if (!mounted) return;

      // ② 弹出可编辑确认弹窗
      final confirmed = await _showConfirmDialog(resp.data!);
      if (confirmed == null || confirmed.isEmpty) return; // 用户取消

      // ③ 批量入库
      setState(() {
        _isUploading = true;
        _uploadStatus = '录入冰箱中...';
        _uploadProgress = 0.95;
      });

      for (final item in confirmed) {
        final name = item.nameCtrl.text;
        final expire = ShelfLifeUtils.estimateExpireDate(
          name: name,
          category: item.category,
        );
        final expireDateStr =
            '${expire.year.toString().padLeft(4, '0')}-'
            '${expire.month.toString().padLeft(2, '0')}-'
            '${expire.day.toString().padLeft(2, '0')}';
        await FridgeService.instance.createItem(
          name: name,
          category: item.category,
          quantity: double.tryParse(item.quantityCtrl.text) ?? 1.0,
          unit: item.unitCtrl.text,
          expireDate: expireDateStr,
        );
      }

      setState(() => _isUploading = false);
      if (!mounted) return;
      Navigator.pop(context, true); // 回到冰箱页并刷新
    } catch (e) {
      _showError('网络错误：$e');
      setState(() => _isUploading = false);
    }
  }

  // ── 识别失败提示（带「重新录制」和「手动添加」两个选项）────────
  void _showRecognitionFailed(String msg) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            SizedBox(width: 8),
            Text('识别失败', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(msg,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('重新录制', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // 返回冰箱页手动添加
            },
            child: const Text('手动添加'),
          ),
        ],
      ),
    );
  }

  // ── 识别结果确认弹窗（可编辑名称/数量/单位）────────────────────
  Future<List<_ConfirmItem>?> _showConfirmDialog(
      List<FridgeItemModel> recognized) async {
    // 把识别结果转成可编辑状态
    final editables =
        recognized.map((e) => _ConfirmItem.fromModel(e)).toList();

    return showModalBottomSheet<List<_ConfirmItem>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmBottomSheet(items: editables),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _durationLabel {
    final m = _recordSeconds ~/ 60;
    final s = _recordSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    _pulseCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isCameraReady && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
              ),
            ),

          // 顶部渐变
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          // 底部渐变
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),

          // 顶部工具栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildTopBar()),
          ),

          // 底部控制区
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildBottomControls()),
          ),

          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '视频扫描食材',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '拍摄冰箱食材，AI 自动识别并录入',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isRecording) ...[
          _buildVoiceWave(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      Colors.red,
                      Colors.red.shade300,
                      _pulseCtrl.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _durationLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '/ 最长 ${_maxRecordSeconds}s',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
        if (!_isRecording)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text(
              '点击录制，缓慢扫过冰箱内的食材\n系统将自动识别并添加到你的冰箱',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Transform.scale(
              scale: _isRecording ? 1.0 + _pulseCtrl.value * 0.05 : 1.0,
              child: _buildRecordButton(),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRecordButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isRecording ? 32 : 64,
          height: _isRecording ? 32 : 64,
          decoration: BoxDecoration(
            color: _isRecording ? Colors.white : Colors.red,
            borderRadius: BorderRadius.circular(_isRecording ? 6 : 32),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceWave() {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          _waveHeights.length,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 3,
            height: _waveHeights[i].clamp(4.0, 48.0),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.85),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  _uploadStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 24),
                const Text(
                  '系统正在识别视频中的食材...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  确认弹窗用的可编辑食材数据类
// ══════════════════════════════════════════════════════════════════
class _ConfirmItem {
  final TextEditingController nameCtrl;
  final TextEditingController quantityCtrl;
  final TextEditingController unitCtrl;
  String category;

  _ConfirmItem({
    required String name,
    required double quantity,
    required String unit,
    required this.category,
  })  : nameCtrl = TextEditingController(text: name),
        quantityCtrl = TextEditingController(
            text: quantity == quantity.toInt()
                ? quantity.toInt().toString()
                : quantity.toStringAsFixed(1)),
        unitCtrl = TextEditingController(text: unit);

  factory _ConfirmItem.fromModel(FridgeItemModel m) => _ConfirmItem(
        name: m.name,
        quantity: m.quantity,
        unit: m.unit ?? '个',
        category: m.category ?? '其他',
      );

  void dispose() {
    nameCtrl.dispose();
    quantityCtrl.dispose();
    unitCtrl.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════
//  识别结果确认底部弹窗
// ══════════════════════════════════════════════════════════════════
class _ConfirmBottomSheet extends StatefulWidget {
  final List<_ConfirmItem> items;
  const _ConfirmBottomSheet({required this.items});

  @override
  State<_ConfirmBottomSheet> createState() => _ConfirmBottomSheetState();
}

class _ConfirmBottomSheetState extends State<_ConfirmBottomSheet> {
  late final List<_ConfirmItem> _items;

  static const _categories = [
    '蔬菜', '水果', '肉类', '海鲜', '蛋类', '乳制品',
    '谷物', '调味品', '饮品', '其他',
  ];

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void dispose() {
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  void _confirm() {
    Navigator.pop<List<_ConfirmItem>>(context, List.of(_items));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 拖动条
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Color(0xFF6C63FF), size: 20),
                  const SizedBox(width: 8),
                  const Text('识别结果确认',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('共 ${_items.length} 种食材',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 20),

            // 食材列表
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text('已全部移除，请重新录制',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (_, i) => _buildItemRow(_items[i], i),
                    ),
            ),

            // 底部按钮
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: Colors.white12,
                      ),
                      onPressed: _items.isEmpty ? null : _confirm,
                      child: const Text('确认入库',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(_ConfirmItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 名称
          Expanded(
            flex: 3,
            child: TextField(
              controller: item.nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: '食材名',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 数量
          SizedBox(
            width: 54,
            child: TextField(
              controller: item.quantityCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 单位
          SizedBox(
            width: 46,
            child: TextField(
              controller: item.unitCtrl,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 分类下拉
          DropdownButton<String>(
            value: _categories.contains(item.category) ? item.category : '其他',
            dropdownColor: const Color(0xFF2A2A3E),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more, color: Colors.white38, size: 16),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => item.category = v ?? '其他'),
          ),
          // 删除
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _removeItem(index),
          ),
        ],
      ),
    );
  }
}
