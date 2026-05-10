import 'package:get/get.dart';

class CommunityController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> posts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMockPosts();
  }

  void loadMockPosts() {
    isLoading.value = true;
    posts.assignAll([
      {
        'author': '轻食打卡员',
        'time': '今天 09:12',
        'content': '午餐做了鸡胸肉沙拉，口感清爽，饱腹感很不错。',
        'tags': ['减脂', '高蛋白'],
        'likes': 12,
        'comments': 4,
        'forks': 2,
        'liked': false,
      },
      {
        'author': '健身厨神',
        'time': '昨天 20:45',
        'content': '用冰箱里快过期的西兰花做了蒜蓉炒菜，低成本又健康。',
        'tags': ['省钱', '赛博冰箱', '低脂'],
        'likes': 28,
        'comments': 9,
        'forks': 6,
        'liked': true,
      },
      {
        'author': '知味志新手',
        'time': '昨天 14:33',
        'content': '第一次尝试记录全天饮食，发现自己早餐蛋白质一直偏低。',
        'tags': ['打卡', '健康习惯'],
        'likes': 6,
        'comments': 3,
        'forks': 1,
        'liked': false,
      },
    ]);
    isLoading.value = false;
  }

  void toggleLike(int index) {
    if (index < 0 || index >= posts.length) return;

    final post = Map<String, dynamic>.from(posts[index]);
    final liked = post['liked'] as bool? ?? false;
    final likes = post['likes'] as int? ?? 0;

    post['liked'] = !liked;
    post['likes'] = liked ? (likes - 1).clamp(0, 1 << 30) : likes + 1;
    posts[index] = post;
  }

  void addMockPost(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    posts.insert(0, {
      'author': '我',
      'time': '刚刚',
      'content': trimmed,
      'tags': ['新动态'],
      'likes': 0,
      'comments': 0,
      'forks': 0,
      'liked': false,
    });
  }
}
