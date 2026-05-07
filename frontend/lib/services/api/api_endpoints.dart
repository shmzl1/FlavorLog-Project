class ApiEndpoints {
  static const String localBaseUrl = 'http://127.0.0.1:8000/api/v1';

  // 真机联调时，把这里改成电脑局域网 IP。
  static const String lanBaseUrl = 'http://192.168.1.100:8000/api/v1';

  static const String baseUrl = localBaseUrl;

  static const String health = '/health';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  static const String foodRecords = '/food-records';
  static const String fridgeItems = '/fridge/items';
  static const String healthFeedbacks = '/health/feedbacks';
  static const String healthBlacklist = '/health/blacklist';
  static const String communityPosts = '/community/posts';

  static const String uploadImage = '/uploads/image';
  static const String uploadVideo = '/uploads/video';
  static const String uploadAudio = '/uploads/audio';
}