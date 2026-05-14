// 文件路径：frontend/lib/services/api/api_endpoints.dart
import 'local_config.dart'; // 引入被 Git 忽略的本地配置文件

class ApiEndpoints {
  // 💡 直接使用每个人本地 local_config.dart 里的 myLocalBaseUrl
  static const String baseUrl = myLocalBaseUrl;

  static const String health = '/health';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  static const String foodRecords = '/food-records/';
  static const String fridgeItems = '/fridge/items/';
  static const String healthFeedbacks = '/health/feedbacks';
  static const String healthBlacklist = '/health/blacklist';
  static const String communityPosts = '/community/posts';

  static const String uploadImage = '/uploads/image';
  static const String uploadVideo = '/uploads/video';
  static const String uploadAudio = '/uploads/audio';

  /// AI 识别 - 视频极速录入饮食记录
  static const String videoFastEntry = '/recognition/video-fast-entry';

  /// 冰箱视频扫描录入
  static const String fridgeScan = '/fridge/scan';
}