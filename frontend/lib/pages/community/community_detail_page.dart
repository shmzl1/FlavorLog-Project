import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/community_controller.dart';
import '../../models/community_model.dart';

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
                _PostDetailCard(
                  post: post,
                  onLike: () => controller.togglePostLike(post),
                  onShare: () async {
                    final ok = await controller.sharePost(post);
                    if (ok) Get.snackbar('已 Fork', '这条灵感已记录到你的社区互动里。');
                  },
                ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 8),
          Text('${post.authorName} · ${post.createdAt}', style: const TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: post.tags.map((tag) => Chip(label: Text(tag), visualDensity: VisualDensity.compact)).toList(),
          ),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF2C3E50))),
          const SizedBox(height: 18),
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
