import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/community_model.dart';
import '../services/api/community_service.dart';

class CommunityController extends GetxController {
  final CommunityService _service = CommunityService.instance;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<CommunityPostModel> posts = <CommunityPostModel>[].obs;
  final RxMap<int, List<CommunityCommentModel>> commentsByPost =
      <int, List<CommunityCommentModel>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadPosts();
  }

  void loadMockPosts() {
    posts.assignAll(_mockPosts());
  }

  /// 根据关键字过滤 mock 帖子（标题/正文/标签匹配即命中），用于本地搜索回退。
  List<CommunityPostModel> _filterMockPosts(String? keyword) {
    final all = _mockPosts();
    final kw = keyword?.trim() ?? '';
    if (kw.isEmpty) return all;
    final lower = kw.toLowerCase();
    return all
        .where((p) =>
            p.title.toLowerCase().contains(lower) ||
            p.content.toLowerCase().contains(lower) ||
            p.tags.any((t) => t.toLowerCase().contains(lower)))
        .toList();
  }

  Future<void> loadPosts({String? keyword, String? tag}) async {
    isLoading.value = true;
    errorMessage.value = '';
    // 默认先把（按关键字过滤后的）mock 帖子铺出来，保证 UI 不会出现空窗
    final fallbackMocks = _filterMockPosts(keyword);
    if (posts.isEmpty) posts.assignAll(fallbackMocks);
    try {
      final resp = await _service.getPosts(keyword: keyword, tag: tag);
      if (resp.isSuccess && resp.data != null) {
        // mock 帖子始终保留在底部，避免发帖 / 搜索后展示区变空
        final merged = <CommunityPostModel>[
          ...resp.data!,
          ...fallbackMocks,
        ];
        posts.assignAll(merged);
      } else {
        debugPrint(
          '[CommunityController] load posts fallback: code=${resp.code}, message=${resp.message}, count=${resp.data?.length ?? 0}',
        );
        posts.assignAll(fallbackMocks);
      }
    } catch (e, st) {
      debugPrint('[CommunityController] load posts exception: $e');
      debugPrint('$st');
      posts.assignAll(fallbackMocks);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty || cleanContent.isEmpty) {
      errorMessage.value = '标题和正文不能为空';
      return false;
    }
    try {
      final resp = await _service.createPost(
        title: cleanTitle,
        content: cleanContent,
        tags: tags.isEmpty ? ['新动态'] : tags,
      );
      if (resp.isSuccess && resp.data != null) {
        await loadPosts();
        return true;
      }
      debugPrint('[CommunityController] create post fallback: ${resp.message}');
    } catch (e, st) {
      debugPrint('[CommunityController] create post exception: $e');
      debugPrint('$st');
    }

    posts.insert(
      0,
      CommunityPostModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        authorName: '我',
        title: cleanTitle,
        content: cleanContent,
        tags: tags.isEmpty ? ['新动态'] : tags,
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        liked: false,
        createdAt: '刚刚',
        isMock: true,
      ),
    );
    return true;
  }

  Future<void> togglePostLike(CommunityPostModel post) async {
    final index = posts.indexWhere((item) => item.id == post.id && item.isMock == post.isMock);
    if (index < 0) return;
    final nextLiked = !post.liked;
    final optimistic = post.copyWith(
      liked: nextLiked,
      likeCount: nextLiked ? post.likeCount + 1 : (post.likeCount - 1).clamp(0, 1 << 30).toInt(),
    );
    posts[index] = optimistic;

    if (post.isMock) return;
    try {
      final resp = await _service.togglePostLike(post.id);
      if (resp.isSuccess && resp.data != null) {
        posts[index] = posts[index].copyWith(
          liked: resp.data!['is_liked'] as bool? ?? posts[index].liked,
          likeCount: resp.data!['like_count'] as int? ?? posts[index].likeCount,
        );
      } else {
        posts[index] = post;
        debugPrint('[CommunityController] toggle post like failed: ${resp.message}');
      }
    } catch (e, st) {
      posts[index] = post;
      debugPrint('[CommunityController] toggle post like exception: $e');
      debugPrint('$st');
    }
  }

  Future<bool> sharePost(CommunityPostModel post, {String shareType = 'fork'}) async {
    final index = posts.indexWhere((item) => item.id == post.id && item.isMock == post.isMock);
    if (post.isMock) {
      if (index >= 0) posts[index] = post.copyWith(shareCount: post.shareCount + 1);
      return true;
    }
    try {
      final resp = await _service.sharePost(post.id, shareType: shareType);
      if (resp.isSuccess && resp.data != null) {
        if (index >= 0) {
          posts[index] = post.copyWith(
            shareCount: resp.data!['share_count'] as int? ?? post.shareCount + 1,
          );
        }
        return true;
      }
      debugPrint('[CommunityController] share post failed: ${resp.message}');
    } catch (e, st) {
      debugPrint('[CommunityController] share post exception: $e');
      debugPrint('$st');
    }
    return false;
  }

  Future<void> loadComments(int postId, {bool isMock = false}) async {
    if (isMock) {
      commentsByPost[postId] = _mockComments(postId);
      return;
    }
    try {
      final resp = await _service.getComments(postId);
      if (resp.isSuccess && resp.data != null) {
        commentsByPost[postId] = resp.data!;
      } else {
        debugPrint('[CommunityController] load comments fallback: ${resp.message}');
        commentsByPost[postId] = _mockComments(postId);
      }
    } catch (e, st) {
      debugPrint('[CommunityController] load comments exception: $e');
      debugPrint('$st');
      commentsByPost[postId] = _mockComments(postId);
    }
  }

  Future<bool> createComment(int postId, String content, {int? parentId, bool isMock = false}) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return false;
    if (!isMock) {
      try {
        final resp = await _service.createComment(postId, content: cleanContent, parentId: parentId);
        if (resp.isSuccess && resp.data != null) {
          await loadComments(postId);
          _bumpPostCommentCount(postId);
          return true;
        }
        debugPrint('[CommunityController] create comment fallback: ${resp.message}');
      } catch (e, st) {
        debugPrint('[CommunityController] create comment exception: $e');
        debugPrint('$st');
      }
    }

    final comment = CommunityCommentModel(
      id: -DateTime.now().millisecondsSinceEpoch,
      postId: postId,
      parentId: parentId,
      authorName: '我',
      content: cleanContent,
      likeCount: 0,
      liked: false,
      createdAt: '刚刚',
      isMock: true,
    );
    final list = List<CommunityCommentModel>.from(commentsByPost[postId] ?? _mockComments(postId));
    if (parentId == null) {
      list.insert(0, comment);
    } else {
      final parentIndex = list.indexWhere((item) => item.id == parentId);
      if (parentIndex >= 0) {
        final parent = list[parentIndex];
        list[parentIndex] = parent.copyWith(replies: [...parent.replies, comment]);
      }
    }
    commentsByPost[postId] = list;
    _bumpPostCommentCount(postId);
    return true;
  }

  Future<void> toggleCommentLike(CommunityCommentModel comment) async {
    if (comment.isMock) {
      _replaceComment(
        comment.postId,
        comment.copyWith(
          liked: !comment.liked,
          likeCount: comment.liked ? (comment.likeCount - 1).clamp(0, 1 << 30).toInt() : comment.likeCount + 1,
        ),
      );
      return;
    }
    try {
      final resp = await _service.toggleCommentLike(comment.id);
      if (resp.isSuccess && resp.data != null) {
        _replaceComment(
          comment.postId,
          comment.copyWith(
            liked: resp.data!['is_liked'] as bool? ?? comment.liked,
            likeCount: resp.data!['like_count'] as int? ?? comment.likeCount,
          ),
        );
      } else {
        debugPrint('[CommunityController] toggle comment like failed: ${resp.message}');
      }
    } catch (e, st) {
      debugPrint('[CommunityController] toggle comment like exception: $e');
      debugPrint('$st');
    }
  }

  void _bumpPostCommentCount(int postId) {
    final index = posts.indexWhere((post) => post.id == postId);
    if (index >= 0) {
      posts[index] = posts[index].copyWith(commentCount: posts[index].commentCount + 1);
    }
  }

  void _replaceComment(int postId, CommunityCommentModel updated) {
    final list = List<CommunityCommentModel>.from(commentsByPost[postId] ?? []);
    for (var i = 0; i < list.length; i++) {
      if (list[i].id == updated.id) {
        list[i] = updated;
        commentsByPost[postId] = list;
        return;
      }
      final replyIndex = list[i].replies.indexWhere((reply) => reply.id == updated.id);
      if (replyIndex >= 0) {
        final replies = List<CommunityCommentModel>.from(list[i].replies);
        replies[replyIndex] = updated;
        list[i] = list[i].copyWith(replies: replies);
        commentsByPost[postId] = list;
        return;
      }
    }
  }

  List<CommunityPostModel> _mockPosts() {
    return const [
      CommunityPostModel(
        id: -1,
        authorName: '减脂课代表',
        title: 'AI秘制泰式柠檬手撕鸡胸肉',
        content: '按照 AI 膳食密语的推荐，酸辣开胃，蛋白质超满足，快来一键克隆。',
        tags: ['最新发现', '减脂热门', '高蛋白肉'],
        likeCount: 241,
        commentCount: 18,
        shareCount: 32,
        liked: false,
        createdAt: '今天 09:12',
        isMock: true,
      ),
      CommunityPostModel(
        id: -2,
        authorName: '甜品制造机',
        title: '冰淇淋口感低卡空气炸锅燕麦糕',
        content: '无油无糖，减脂期想吃甜食也可以试试，饱腹感很稳。',
        tags: ['最新发现', '减脂热门', 'AI 脑洞食谱'],
        likeCount: 942,
        commentCount: 64,
        shareCount: 87,
        liked: true,
        createdAt: '昨天 20:45',
        isMock: true,
      ),
      CommunityPostModel(
        id: -3,
        authorName: '赛博小当家',
        title: '清空冰箱大作战：智能魔芋意面',
        content: '把剩下的西红柿和蔬菜完美消灭，低卡又不浪费。',
        tags: ['最新发现', '纯素沙拉', '赛博冰箱'],
        likeCount: 108,
        commentCount: 9,
        shareCount: 14,
        liked: false,
        createdAt: '昨天 14:33',
        isMock: true,
      ),
    ];
  }

  List<CommunityCommentModel> _mockComments(int postId) {
    return [
      CommunityCommentModel(
        id: postId * 100 - 1,
        postId: postId,
        authorName: '轻食打卡员',
        content: '这个搭配看起来很适合工作日午餐，我准备明天试试。',
        likeCount: 6,
        liked: false,
        createdAt: '刚刚',
        isMock: true,
        replies: [
          CommunityCommentModel(
            id: postId * 100 - 2,
            postId: postId,
            parentId: postId * 100 - 1,
            authorName: '作者',
            content: '可以把柠檬汁多放一点，口感会更清爽。',
            likeCount: 3,
            liked: false,
            createdAt: '刚刚',
            isMock: true,
          ),
        ],
      ),
    ];
  }
}
