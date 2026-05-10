import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/community_controller.dart';
import '../../components/empty_state.dart';
import '../../components/tag_chip.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CommunityController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('社区动态'),
        actions: [
          IconButton(
            tooltip: '发布动态',
            onPressed: () => _showCreatePostDialog(context, controller),
            icon: const Icon(Icons.edit_note),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.posts.isEmpty) {
          return EmptyState(
            title: '还没有动态',
            message: '先发布你的第一条饮食打卡吧。',
            icon: Icons.forum_outlined,
            actionLabel: '发布动态',
            onAction: () => _showCreatePostDialog(context, controller),
          );
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: FilledButton.icon(
                onPressed: () => _showCreatePostDialog(context, controller),
                icon: const Icon(Icons.add_comment),
                label: const Text('发布动态'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                itemCount: controller.posts.length,
                itemBuilder: (context, index) {
                  final post = controller.posts[index];
                  return _PostCard(
                    post: post,
                    onLikeTap: () => controller.toggleLike(index),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showCreatePostDialog(
    BuildContext context,
    CommunityController controller,
  ) async {
    final inputController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('发布动态'),
          content: TextField(
            controller: inputController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '分享今天的饮食、烹饪心得或健康感受',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                controller.addMockPost(inputController.text);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('发布成功（Mock）')),
                );
              },
              child: const Text('发布'),
            ),
          ],
        );
      },
    );

    inputController.dispose();
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLikeTap,
  });

  final Map<String, dynamic> post;
  final VoidCallback onLikeTap;

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as String? ?? '匿名用户';
    final time = post['time'] as String? ?? '';
    final content = post['content'] as String? ?? '';
    final tags = (post['tags'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => e.toString())
        .toList();
    final likes = post['likes'] as int? ?? 0;
    final comments = post['comments'] as int? ?? 0;
    final forks = post['forks'] as int? ?? 0;
    final liked = post['liked'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    author.isNotEmpty ? author.substring(0, 1) : '匿',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(author,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: tags.map((tag) => TagChip(label: '#$tag')).toList(),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onLikeTap,
                  icon: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? Colors.red : null,
                  ),
                  label: Text('$likes'),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.mode_comment_outlined, size: 18),
                    const SizedBox(width: 4),
                    Text('$comments'),
                  ],
                ),
                const SizedBox(width: 14),
                Row(
                  children: [
                    const Icon(Icons.call_split_outlined, size: 18),
                    const SizedBox(width: 4),
                    Text('$forks'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

