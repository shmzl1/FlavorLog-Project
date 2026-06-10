class CommunityPostModel {
  final int id;
  final String authorName;
  final String title;
  final String content;
  final List<String> tags;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool liked;
  final String createdAt;
  final bool isMock;

  const CommunityPostModel({
    required this.id,
    required this.authorName,
    required this.title,
    required this.content,
    required this.tags,
    this.imageUrls = const [],
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.liked,
    required this.createdAt,
    this.isMock = false,
  });

  /// 给 UI 直接展示的时间文本。
  /// - 后端返回的 ISO 格式（如 2026-06-09T10:30:00.000Z）会被解析为本地时间并展示成「刚刚 / 5 分钟前 / 今天 HH:mm / yyyy-MM-dd HH:mm」；
  /// - mock 帖子里已经是 “今天 09:12” 这样的文本则原样保留。
  String get displayCreatedAt => _formatCreatedAt(createdAt);

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final imageUrls = (json['image_urls'] as List<dynamic>? ?? [])
        .map((e) => '$e')
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final coverUrl = json['cover_url'] as String?;
    if (imageUrls.isEmpty && coverUrl != null && coverUrl.trim().isNotEmpty) {
      imageUrls.add(coverUrl.trim());
    }

    return CommunityPostModel(
      id: json['id'] as int? ?? 0,
      authorName: (json['author_name'] as String?) ??
          (json['nickname'] as String?) ??
          (json['author'] as String?) ??
          '知味志用户',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      imageUrls: imageUrls,
      likeCount: (json['like_count'] as int?) ?? (json['likes'] as int?) ?? 0,
      commentCount: (json['comment_count'] as int?) ?? (json['comments'] as int?) ?? 0,
      shareCount: (json['share_count'] as int?) ??
          (json['fork_count'] as int?) ??
          (json['forks'] as int?) ??
          0,
      liked: (json['is_liked'] as bool?) ?? (json['liked'] as bool?) ?? false,
      createdAt: (json['created_at'] as String?) ?? (json['time'] as String?) ?? '',
      isMock: (json['is_mock'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'title': title,
      'content': content,
      'tags': tags,
      'image_urls': imageUrls,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_liked': liked,
      'created_at': createdAt,
      'is_mock': isMock,
    };
  }

  CommunityPostModel copyWith({
    int? id,
    String? authorName,
    String? title,
    String? content,
    List<String>? tags,
    List<String>? imageUrls,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? liked,
    String? createdAt,
    bool? isMock,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      liked: liked ?? this.liked,
      createdAt: createdAt ?? this.createdAt,
      isMock: isMock ?? this.isMock,
    );
  }
}

class CommunityCommentModel {
  final int id;
  final int postId;
  final int? parentId;
  final String authorName;
  final String content;
  final int likeCount;
  final bool liked;
  final String createdAt;
  final List<CommunityCommentModel> replies;
  final bool isMock;

  const CommunityCommentModel({
    required this.id,
    required this.postId,
    this.parentId,
    required this.authorName,
    required this.content,
    required this.likeCount,
    required this.liked,
    required this.createdAt,
    this.replies = const [],
    this.isMock = false,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: json['id'] as int? ?? 0,
      postId: json['post_id'] as int? ?? 0,
      parentId: json['parent_id'] as int?,
      authorName: (json['author_name'] as String?) ?? (json['nickname'] as String?) ?? '知味志用户',
      content: json['content'] as String? ?? '',
      likeCount: json['like_count'] as int? ?? 0,
      liked: (json['is_liked'] as bool?) ?? (json['liked'] as bool?) ?? false,
      createdAt: json['created_at'] as String? ?? '',
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => CommunityCommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isMock: (json['is_mock'] as bool?) ?? false,
    );
  }

  CommunityCommentModel copyWith({
    int? likeCount,
    bool? liked,
    List<CommunityCommentModel>? replies,
  }) {
    return CommunityCommentModel(
      id: id,
      postId: postId,
      parentId: parentId,
      authorName: authorName,
      content: content,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
      createdAt: createdAt,
      replies: replies ?? this.replies,
      isMock: isMock,
    );
  }

  String get displayCreatedAt => _formatCreatedAt(createdAt);
}

/// 将后端 ISO 时间字符串格式化为面向用户的可读字符串。
/// - 非 ISO 字符串（mock 数据中的 "今天 09:12" / "刚刚" 等）会原样返回；
/// - ISO 字符串按本地时区显示成「刚刚 / N 分钟前 / 今天 HH:mm / 昨天 HH:mm / yyyy-MM-dd HH:mm」。
String _formatCreatedAt(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value; // 非 ISO 字符串原样展示
  final local = parsed.isUtc ? parsed.toLocal() : parsed;
  final now = DateTime.now();
  final diff = now.difference(local);

  if (diff.inSeconds < 60 && !diff.isNegative) return '刚刚';
  if (diff.inMinutes < 60 && !diff.isNegative) return '${diff.inMinutes} 分钟前';

  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final today = DateTime(now.year, now.month, now.day);
  final localDay = DateTime(local.year, local.month, local.day);
  final dayDiff = today.difference(localDay).inDays;

  if (dayDiff == 0) return '今天 $hh:$mm';
  if (dayDiff == 1) return '昨天 $hh:$mm';
  if (local.year == now.year) {
    final mo = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$mo-$d $hh:$mm';
  }
  final mo = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mo-$d $hh:$mm';
}
