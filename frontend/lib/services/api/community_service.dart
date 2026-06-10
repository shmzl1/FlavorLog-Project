import '../../models/api_response.dart';
import '../../models/community_model.dart';
import 'api_client.dart';
import 'api_endpoints.dart';

class CommunityService {
  CommunityService._();
  static final CommunityService instance = CommunityService._();

  final ApiClient _client = ApiClient.instance;

  Future<ApiResponse<List<CommunityPostModel>>> getPosts({
    int page = 1,
    int pageSize = 20,
    String? keyword,
    String? tag,
    bool onlyMine = false,
  }) async {
    final resp = await _client.get(
      ApiEndpoints.communityPosts,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
        if (onlyMine) 'only_mine': onlyMine,
      },
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => (raw as List<dynamic>? ?? [])
          .map((e) => CommunityPostModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<CommunityPostModel>> createPost({
    required String title,
    required String content,
    List<String> tags = const [],
    List<String> imageUrls = const [],
    String sourceType = 'manual',
  }) async {
    final resp = await _client.post(
      ApiEndpoints.communityPosts,
      data: {
        'title': title,
        'content': content,
        'tags': tags,
        'image_urls': imageUrls,
        if (imageUrls.isNotEmpty) 'cover_url': imageUrls.first,
        'source_type': sourceType,
        'visibility': 'public',
      },
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => CommunityPostModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CommunityPostModel>> getPostDetail(int postId) async {
    final resp = await _client.get('${ApiEndpoints.communityPosts}/$postId');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => CommunityPostModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> togglePostLike(int postId) async {
    final resp = await _client.post('${ApiEndpoints.communityPosts}/$postId/like');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }

  Future<ApiResponse<Map<String, dynamic>>> sharePost(int postId, {String shareType = 'fork'}) async {
    final resp = await _client.post(
      '${ApiEndpoints.communityPosts}/$postId/share',
      data: {'share_type': shareType},
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }

  Future<ApiResponse<List<CommunityCommentModel>>> getComments(int postId) async {
    final resp = await _client.get('${ApiEndpoints.communityPosts}/$postId/comments');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => (raw as List<dynamic>? ?? [])
          .map((e) => CommunityCommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<CommunityCommentModel>> createComment(
    int postId, {
    required String content,
    int? parentId,
  }) async {
    final resp = await _client.post(
      '${ApiEndpoints.communityPosts}/$postId/comments',
      data: {
        'content': content,
        if (parentId != null) 'parent_id': parentId,
      },
    );
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(
      json,
      (raw) => CommunityCommentModel.fromJson(raw as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> toggleCommentLike(int commentId) async {
    final resp = await _client.post('/community/comments/$commentId/like');
    final json = resp.data as Map<String, dynamic>;
    return ApiResponse.fromJson(json, (raw) => raw as Map<String, dynamic>);
  }
}
