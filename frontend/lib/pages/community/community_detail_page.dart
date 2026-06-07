import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/community_controller.dart';
import '../../models/community_model.dart';
import '../../services/api/upload_service.dart';

class CommunityDetailPage extends StatefulWidget {
  const CommunityDetailPage({super.key});

  @override
  State<CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<CommunityDetailPage> {
  final CommunityController controller = Get.find<CommunityController>();
  final TextEditingController commentCtrl = TextEditingController();
  CommunityPostModel get post => Get.arguments as CommunityPostModel;
  int? replyingTo;

  CommunityPostModel _resolvedPost() {
    for (final item in controller.posts) {
      if (item.id == post.id && item.isMock == post.isMock) return item;
    }
    return post;
  }

  @override
  void initState() {
    super.initState();
    controller.loadComments(post.id, isMock: post.isMock);
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('灵感详情'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
              children: [
                Obx(() {
                  final currentPost = _resolvedPost();
                  return _PostDetailCard(
                    post: currentPost,
                    onLike: () => controller.togglePostLike(currentPost),
                    onShare: () async {
                      final ok = await controller.sharePost(currentPost);
                      if (ok) Get.snackbar('\u5df2 Fork', '\u8fd9\u6761\u7075\u611f\u5df2\u8bb0\u5f55\u5230\u4f60\u7684\u793e\u533a\u4e92\u52a8\u91cc\u3002');
                    },
                  );
                }),
                const SizedBox(height: 18),
                const Text('评论', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                Obx(() {
                  final comments = controller.commentsByPost[post.id] ?? [];
                  if (comments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Text('还没有评论，来坐第一排。')),
                    );
                  }
                  return Column(
                    children: comments
                        .map(
                          (comment) => _CommentTile(
                            comment: comment,
                            onLike: () => controller.toggleCommentLike(comment),
                            onReply: () {
                              setState(() => replyingTo = comment.id);
                              commentCtrl.text = '@${comment.authorName} ';
                            },
                          ),
                        )
                        .toList(),
                  );
                }),
              ],
            ),
          ),
          _CommentInput(
            controller: commentCtrl,
            replying: replyingTo != null,
            onCancelReply: () => setState(() {
              replyingTo = null;
              commentCtrl.clear();
            }),
            onSubmit: () async {
              final ok = await controller.createComment(
                post.id,
                commentCtrl.text,
                parentId: replyingTo,
                isMock: post.isMock,
              );
              if (ok) {
                setState(() => replyingTo = null);
                commentCtrl.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _PostDetailCard extends StatelessWidget {
  const _PostDetailCard({required this.post, required this.onLike, required this.onShare});

  final CommunityPostModel post;
  final VoidCallback onLike;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailImageGallery(imageUrls: post.imageUrls),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFFF6B35),
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.createdAt,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E), height: 1.35),
                ),
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 15, height: 1.7, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                ),
                if (post.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: post.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF2F2F7)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ActionButton(icon: post.liked ? Icons.favorite : Icons.favorite_border, label: '${post.likeCount}', onTap: onLike),
                    const SizedBox(width: 10),
                    _ActionButton(icon: Icons.mode_comment_outlined, label: '${post.commentCount}', onTap: () {}),
                    const SizedBox(width: 10),
                    _ActionButton(icon: Icons.fork_right_rounded, label: '${post.shareCount}', onTap: onShare),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImageGallery extends StatelessWidget {
  const _DetailImageGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const _DetailImagePlaceholder();
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        itemCount: imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final radius = BorderRadius.circular(18);
          return ClipRRect(
            borderRadius: radius,
            child: Image.network(
              resolveImageUrl(imageUrls[index]),
              width: MediaQuery.of(context).size.width - 60,
              height: 256,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DetailImagePlaceholder(width: 260, radius: 18),
            ),
          );
        },
      ),
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder({this.width, this.radius = 24});

  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: width == null ? const BorderRadius.vertical(top: Radius.circular(24)) : BorderRadius.circular(radius),
      child: Container(
        height: width == null ? 260 : 256,
        width: width ?? double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD3A5), Color(0xFFFF6B35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 72),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 4), Text(label)]),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onLike, required this.onReply});

  final CommunityCommentModel comment;
  final VoidCallback onLike;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(comment.content, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(comment.liked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 16),
                label: Text('${comment.likeCount}'),
              ),
              TextButton(onPressed: onReply, child: const Text('回复')),
            ],
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 8),
              child: Column(
                children: comment.replies
                    .map(
                      (reply) => _CommentTile(
                        comment: reply,
                        onLike: () => Get.find<CommunityController>().toggleCommentLike(reply),
                        onReply: onReply,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  const _CommentInput({
    required this.controller,
    required this.replying,
    required this.onCancelReply,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool replying;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: replying ? '回复评论...' : '写下你的想法...',
                  suffixIcon: replying ? IconButton(icon: const Icon(Icons.close), onPressed: onCancelReply) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSubmit,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
