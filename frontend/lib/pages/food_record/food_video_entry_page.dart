import 'dart:async';
import 'dart:math' show sin;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import '../../services/api/food_record_service.dart';
import 'food_video_result_page.dart';

/// 饮食记录 - 视频连续录入页
/// 用户录制一段视频并口述食物信息，AI 自动识别后进入结果确认页
class FoodVideoEntryPage extends StatefulWidget {
  const FoodVideoEntryPage({super.key});

  @override
  State<FoodVideoEntryPage> createState() => _FoodVideoEntryPageState();
}

class _FoodVideoEntryPageState extends State<FoodVideoEntryPage>
    with TickerProviderStateMixin {
  // ── 相机 ──────────────────────────────────────────────────
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _isSimulationMode = false;

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
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _isSimulationMode = true);
        return;
      }
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _isCameraReady = true);
    } catch (e) {
      debugPrint('相机初始化失败: $e');
      if (mounted) {
        setState(() {
          _isSimulationMode = true;
          _isCameraReady = false;
        });
      }
    }
  }

  void _startMockRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= _maxRecordSeconds) _stopMockRecording();
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) return;
      setState(() {
        _wavePhase = (_wavePhase + 1) % 360;
        for (int i = 0; i < _waveHeights.length; i++) {
          final angle =
              (i / _waveHeights.length + _wavePhase / 360.0) * 2 * 3.14159;
          _waveHeights[i] = 4.0 + 22.0 * ((1 + sin(angle * 3.7 + i * 0.8)) / 2);
        }
      });
    });
  }

  void _stopMockRecording() {
    _recordTimer?.cancel();
    _waveTimer?.cancel();
    setState(() => _isRecording = false);
    _uploadMockVideo();
  }

  Future<void> _uploadMockVideo() async {
    setState(() {
      _isUploading = true;
      _uploadStatus = '模拟上传视频中...';
      _uploadProgress = 0.1;
    });
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _uploadStatus = 'AI 识别食物中 (使用模拟测试数据)...';
      _uploadProgress = 0.45;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _uploadStatus = '生成模拟识别草稿中...';
      _uploadProgress = 0.85;
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _uploadProgress = 1.0;
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isUploading = false);

    final mockDrafts = [
      {
        'meal_type': 'lunch',
        'record_time': DateTime.now().toIso8601String(),
        'description': 'AI 自动模拟识别午餐，包含经典黑椒牛肉意面和健康轻食。',
        'items': [
          {
            'food_name': '黑椒牛肉意面',
            'weight_g': 350.0,
            'calories': 520.0,
            'protein_g': 28.5,
            'fat_g': 12.0,
            'carbohydrate_g': 68.0,
            'confidence': 0.95,
          },
          {
            'food_name': '水煮西兰花',
            'weight_g': 100.0,
            'calories': 34.0,
            'protein_g': 3.0,
            'fat_g': 0.2,
            'carbohydrate_g': 7.0,
            'confidence': 0.88,
          },
          {
            'food_name': '西柚柠檬苏打',
            'weight_g': 250.0,
            'calories': 65.0,
            'protein_g': 0.5,
            'fat_g': 0.1,
            'carbohydrate_g': 16.0,
            'confidence': 0.74,
          }
        ],
      }
    ];

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodVideoResultPage(drafts: mockDrafts),
      ),
    );

    if (!mounted) return;
    if (saved == true) Navigator.pop(context, true);
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
            _waveHeights[i] = 4.0 + 22.0 * ((1 + sin(angle * 3.7 + i * 0.8)) / 2);
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

  // ── 上传并识别 ────────────────────────────────────────────
  Future<void> _uploadVideo(String path) async {
    setState(() {
      _isUploading = true;
      _uploadStatus = '上传视频中...';
      _uploadProgress = 0.1;
    });
    try {
      setState(() {
        _uploadStatus = 'AI 识别食物中...';
        _uploadProgress = 0.35;
      });
      final resp = await FoodRecordService.instance.videoFastEntry(path);
      setState(() {
        _uploadProgress = 0.9;
        _uploadStatus = '生成草稿中...';
      });

      if (!resp.isSuccess || resp.data == null) {
        _showError(resp.message.isNotEmpty ? resp.message : '识别失败，请重试');
        setState(() => _isUploading = false);
        return;
      }
      final drafts = resp.data!;
      if (drafts.isEmpty) {
        _showError('未能识别到食物，请重新录制并清晰展示食物');
        setState(() => _isUploading = false);
        return;
      }

      if (!mounted) return;
      setState(() => _isUploading = false);

      final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => FoodVideoResultPage(drafts: drafts),
        ),
      );

      if (!mounted) return;
      if (saved == true) Navigator.pop(context, true);
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
          else if (_isSimulationMode)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.videocam_off_rounded,
                              color: Color(0xFFFF6B35),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '未检测到摄像头设备',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '当前处于安卓模拟器或无物理相机环境，已自动为您启用「AI模拟测试模式」。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _uploadMockVideo,
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text('一键测试 AI 识别流光页'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFFFF6B35),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '正在初始化相机设备...',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
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
                  '视频录入饮食',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '边拍边说，AI 自动识别食物信息',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _uploadMockVideo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A5C), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    '模拟识别',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
              '点击录制，对着食物说出名称和份量\n如："这是一碗米饭大概 200 克，还有红烧肉 100 克"',
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
          onTap: () {
            if (_isSimulationMode) {
              if (_isRecording) {
                _stopMockRecording();
              } else {
                _startMockRecording();
              }
            } else {
              if (_isRecording) {
                _stopRecording();
              } else {
                _startRecording();
              }
            }
          },
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
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // 磨砂玻璃科技感大底座
          child: Container(
            color: Colors.black.withOpacity(0.55), // 微透的黑色更显呼吸感
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 渐变光环脉冲雷达环
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF6B35),
                          strokeWidth: 3.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      _uploadStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '💡 系统正深度调动 AI 解析视频帧与语音数据...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
