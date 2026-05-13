import 'dart:async';
import 'dart:math' show sin;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/api/fridge_service.dart';
import 'fridge_video_result_page.dart';

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
        _uploadStatus = 'YOLO 识别食材中...';
        _uploadProgress = 0.35;
      });
      final resp = await FridgeService.instance.scanFromVideo(path);
      setState(() {
        _uploadProgress = 0.9;
        _uploadStatus = '录入冰箱中...';
      });

      if (!resp.isSuccess || resp.data == null) {
        _showError(resp.message.isNotEmpty ? resp.message : '识别失败，请重试');
        setState(() => _isUploading = false);
        return;
      }
      final items = resp.data!;
      if (items.isEmpty) {
        _showError('未能检测到食材，请重新录制并对准食材');
        setState(() => _isUploading = false);
        return;
      }

      if (!mounted) return;
      setState(() => _isUploading = false);

      final done = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => FridgeVideoResultPage(scannedItems: items),
        ),
      );

      if (!mounted) return;
      if (done == true) Navigator.pop(context, true);
    } catch (e) {
      _showError('网络错误：$e');
      setState(() => _isUploading = false);
    }
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
