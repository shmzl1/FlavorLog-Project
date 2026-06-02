import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/community_controller.dart';
import '../../models/community_model.dart';

class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({super.key});

  static const List<String> _tabs = ['最新发现', '减脂热门', '纯素沙拉', '高蛋白肉', 'AI 脑洞食谱'];

  @override
  Widget build(BuildContext context) {
    final selectedCategory = '最新发现'.obs;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: _PublishButton(controller: controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Obx(() {
        final posts = _filterPosts(controller.posts, selectedCategory.value);
        return RefreshIndicator(
          onRefresh: controller.loadPosts,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _CategoryTabs(
                    tabs: _tabs,
                    selected: selectedCategory.value,
                    onSelected: (value) => selectedCategory.value = value,
                  ),
                ),
              ),
              if (controller.isLoading.value && controller.posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (posts.isEmpty)
                const SliverToBoxAdapter(child: _CommunityEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.58,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _PostCard(
                        post: posts[index],
                        controller: controller,
                      ),
                      childCount: posts.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  List<CommunityPostModel> _filterPosts(List<CommunityPostModel> posts, String category) {
    if (category == '最新发现') return posts;
    return posts.where((post) => post.tags.contains(category)).toList();
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      backgroundColor: const Color(0xFFF8F9FA).withOpacity(0.85),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 54, right: 16, bottom: 10),
            centerTitle: false,
            title: SizedBox(
              height: 38,
              child: TextField(
                style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: '探索低卡轻食、AI 隐藏食谱...',
                  hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E93), size: 16),
                  filled: true,
                  fillColor: const Color(0xFFEFEFF4),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(19), borderSide: BorderSide.none),
                ),
                onSubmitted: (value) => controller.loadPosts(keyword: value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.tabs, required this.selected, required this.onSelected});

  final List<String> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = tab == selected;
          return GestureDetector(
            onTap: () => onSelected(tab),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1C1C1E).withOpacity(isSelected ? 0.15 : 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.controller});

  final CommunityPostModel post;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Get.toNamed(AppRoutes.communityDetail, arguments: post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.03), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 108,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD3A5), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 36),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TagPill(label: post.tags.isEmpty ? '灵感' : post.tags.first),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF636E72), height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFF2F2F7)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 8,
                          backgroundColor: Color(0xFFFF6B35),
                          child: Icon(Icons.person, size: 8, color: Colors.white),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.authorName,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF8E8E93), fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => controller.togglePostLike(post),
                          child: Icon(
                            post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: const Color(0xFFFF4757),
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text('${post.likeCount}', style: const TextStyle(fontSize: 10, color: Color(0xFF636E72), fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () async {
                            final ok = await controller.sharePost(post);
                            if (ok) {
                              Get.snackbar('已 Fork', '已记录这条灵感，稍后可以继续整理成菜谱。');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFF20BF6B).withOpacity(0.12), shape: BoxShape.circle),
                            child: const Icon(Icons.fork_right_rounded, color: Color(0xFF20BF6B), size: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFFFF6B35).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.controller});
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1C1C1E), Color(0xFF3A3A3C)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1C1C1E).withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => _showPublishSheet(context),
          child: const Center(
            child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  void _showPublishSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final tagCtrl = TextEditingController(text: '最新发现');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '发布灵感',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: titleCtrl,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700),
                  decoration: _sheetInputDecoration('标题'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  minLines: 4,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), height: 1.5),
                  decoration: _sheetInputDecoration('正文'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagCtrl,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700),
                  decoration: _sheetInputDecoration('标签，用逗号分隔'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () async {
                      final tags = tagCtrl.text
                          .split(RegExp(r'[,，]'))
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      final ok = await controller.createPost(
                        title: titleCtrl.text,
                        content: contentCtrl.text,
                        tags: tags,
                      );
                      if (ok && sheetContext.mounted) Navigator.of(sheetContext).pop();
                    },
                    child: const Text('发布'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _sheetInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: const Color(0xFFF5F5F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.2),
      ),
    );
  }
}

class _CommunityEmptyState extends StatelessWidget {
  const _CommunityEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.explore_off_rounded, size: 60, color: const Color(0xFF8E8E93).withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text('暂无该分类的灵感内容', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
