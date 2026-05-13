import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// 相机与图库调用服务
/// 封装拍照、录像、从相册选取图片/视频的能力
class CameraService {
  CameraService._internal();

  static final CameraService instance = CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  // ────────────────────────── 权限 ──────────────────────────

  /// 请求相机权限，返回是否已授权
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 检查相机权限（不弹弹窗）
  Future<bool> hasCameraPermission() async {
    return Permission.camera.isGranted;
  }

  // ────────────────────────── 图片 ──────────────────────────

  /// 拍照，返回图片文件；用户取消或无权限返回 null
  Future<File?> takePhoto({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    final granted = await requestCameraPermission();
    if (!granted) return null;

    final xFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// 从相册选择图片，返回图片文件；用户取消返回 null
  Future<File?> pickImageFromGallery({
    int imageQuality = 85,
  }) async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  // ────────────────────────── 视频 ──────────────────────────

  /// 录制视频，返回视频文件；用户取消或无权限返回 null
  Future<File?> recordVideo({
    Duration maxDuration = const Duration(minutes: 5),
  }) async {
    final granted = await requestCameraPermission();
    if (!granted) return null;

    final xFile = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }

  /// 从相册选择视频，返回视频文件；用户取消返回 null
  Future<File?> pickVideoFromGallery({
    Duration maxDuration = const Duration(minutes: 10),
  }) async {
    final xFile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
    if (xFile == null) return null;
    return File(xFile.path);
  }
}
