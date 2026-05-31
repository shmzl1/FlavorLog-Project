class CommunityPostModel {
  final int id;
  final String authorName;
  final String title;
  final String content;
  final List<String> tags;
  final String? coverUrl;
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
    this.coverUrl,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.liked,
    required this.createdAt,
    this.isMock = false,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] as int? ?? 0,
      authorName: (json['author_name'] as String?) ??
          (json['nickname'] as String?) ??
          (json['author'] as String?) ??
          '知味志用户',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      coverUrl: json['cover_url'] as String?,
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

  CommunityPostModel copyWith({
    int? id,
    String? authorName,
    String? title,
    String? content,
    List<String>? tags,
    String? coverUrl,
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
      coverUrl: coverUrl ?? this.coverUrl,
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
}
