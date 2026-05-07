class CommunityPostModel {
  final int id;
  final int userId;
  final String title;
  final String? content;
  final int likeCount;
  final int commentCount;
  final int forkCount;

  CommunityPostModel({
    required this.id,
    required this.userId,
    required this.title,
    this.content,
    required this.likeCount,
    required this.commentCount,
    required this.forkCount,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    return CommunityPostModel(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      forkCount: json['fork_count'] as int? ?? 0,
    );
  }
}