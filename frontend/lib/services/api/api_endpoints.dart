import 'local_config.dart';

class ApiEndpoints {
  // 💡 安卓模拟器用这个 IP
  static const String localBaseUrl = 'http://10.0.2.2:8000/api/v1';

  // 真机联调时，把这里改成电脑局域网 IP。
  static const String lanBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // 切换：模拟器用 localBaseUrl，真机用 lanBaseUrl，这里从本地 local_config.dart 动态读取
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