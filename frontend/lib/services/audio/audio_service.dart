import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 麦克风与音频录制服务
///
/// 依赖 `record` 包（pubspec.yaml 已添加）：
///   - 跨平台音频录制（Android / iOS / Windows / macOS / Linux / Web）
///   - 支持 AAC、WAV、FLAC、MP4 等编解码格式
///   - 提供录制状态查询、振幅监听能力
///
/// 本服务封装了完整的录制生命周期：
///   1. 权限申请（麦克风）
///   2. 开始录制（生成临时文件路径，使用 WAV 格式）
///   3. 停止录制（返回录音文件路径）
///   4. 文件校验与清理
///   5. 上传由调用方通过 FoodRecordService.uploadAudio 完成
class AudioService {
  AudioService._internal();

  static final AudioService instance = AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;

  /// 当前是否正在录音
  bool get isRecording => _isRecording;

  // ────────────────────────── 权限 ──────────────────────────

  /// 请求麦克风权限，返回是否已授权
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 检查麦克风权限（不弹弹窗）
  Future<bool> hasMicrophonePermission() async {
    return Permission.microphone.isGranted;
  }

  // ────────────────────────── 录制控制 ──────────────────────────

  /// 开始录音
  ///
  /// 自动申请麦克风权限，生成临时 WAV 文件路径后开始录制。
  /// 权限被拒绝时返回 false，录制成功启动返回 true。
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    final granted = await requestMicrophonePermission();
    if (!granted) return false;

    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = p.join(dir.path, 'audio_$timestamp.wav');

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // 16kHz，适合语音识别
        numChannels: 1,    // 单声道
      ),
      path: path,
    );
    _isRecording = true;
    return true;
  }

  /// 停止录音，返回录音文件路径
  ///
  /// 录制未启动时返回 null。
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  /// 取消录音（停止并丢弃文件）
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    final path = await _recorder.stop();
    _isRecording = false;
    if (path != null) await deleteTempFile(path);
  }

  // ────────────────────────── 文件校验 ──────────────────────────

  /// 检查音频文件是否有效（存在且大小 > 0）
  Future<bool> isValidAudioFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 0;
  }

  /// 删除临时录音文件（上传完成后调用）
  Future<void> deleteTempFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 释放录制器资源（页面销毁时调用）
  Future<void> dispose() async {
    if (_isRecording) await _recorder.stop();
    _recorder.dispose();
    _isRecording = false;
  }
}
