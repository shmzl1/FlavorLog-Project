import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/community_controller.dart';
import '../../models/community_model.dart';
import '../../services/api/upload_service.dart';

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
            _PostCoverImage(imageUrl: post.coverUrl),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TagPill(label: post.tags.isEmpty ? '\u7075\u611f' : post.tags.first),
                    const SizedBox(height: 6),
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF636E72), height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    _PostCardFooter(post: post, controller: controller),
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

class _PostCoverImage extends StatelessWidget {
  const _PostCoverImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.trim().isEmpty) {
      return const _PostCoverPlaceholder(height: 108, iconSize: 36);
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Image.network(
        resolveImageUrl(url),
        height: 108,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PostCoverPlaceholder(height: 108, iconSize: 36),
      ),
    );
  }
}

class _PostCoverPlaceholder extends StatelessWidget {
  const _PostCoverPlaceholder({required this.height, required this.iconSize});

  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
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
      child: Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: iconSize),
    );
  }
}

class _PostCardFooter extends StatelessWidget {
  const _PostCardFooter({required this.post, required this.controller});

  final CommunityPostModel post;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final displayId = post.authorName.trim().isEmpty ? 'ID ${post.id.abs()}' : post.authorName.trim();
    return Row(
      children: [
        const CircleAvatar(
          radius: 10,
          backgroundColor: Color(0xFFFF6B35),
          child: Icon(Icons.person, size: 10, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            displayId,
            style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93), fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: () => controller.togglePostLike(post),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: post.liked ? const Color(0xFFFF4757) : const Color(0xFF8E8E93),
                  size: 15,
                ),
                const SizedBox(width: 3),
                Text(
                  '${post.likeCount}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF636E72), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
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
    final tagCtrl = TextEditingController(text: '\u6700\u65b0\u53d1\u73b0');
    final picker = ImagePicker();
    final selectedImages = <XFile>[];
    var isPublishing = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        Future<void> appendImages(List<XFile> files, StateSetter setSheetState) async {
          if (files.isEmpty) return;
          final remain = 6 - selectedImages.length;
          if (remain <= 0) {
            Get.snackbar('\u63d0\u793a', '\u6700\u591a\u4e0a\u4f20 6 \u5f20\u56fe\u7247');
            return;
          }
          final appendList = files.take(remain).toList();
          setSheetState(() => selectedImages.addAll(appendList));
          if (files.length > remain) {
            Get.snackbar('\u63d0\u793a', '\u6700\u591a\u4e0a\u4f20 6 \u5f20\u56fe\u7247');
          }
        }

        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                      '\u53d1\u5e03\u7075\u611f',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: titleCtrl,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700),
                      decoration: _sheetInputDecoration('\u6807\u9898'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentCtrl,
                      minLines: 4,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), height: 1.5),
                      decoration: _sheetInputDecoration('\u6b63\u6587'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagCtrl,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700),
                      decoration: _sheetInputDecoration('\u6807\u7b7e\uff0c\u7528\u9017\u53f7\u5206\u9694'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isPublishing
                                ? null
                                : () async {
                                    final files = await picker.pickMultiImage();
                                    await appendImages(files, setSheetState);
                                  },
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('\u4ece\u76f8\u518c\u9009\u62e9'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isPublishing
                                ? null
                                : () async {
                                    final file = await picker.pickImage(source: ImageSource.camera);
                                    if (file != null) await appendImages([file], setSheetState);
                                  },
                            icon: const Icon(Icons.photo_camera_outlined, size: 18),
                            label: const Text('\u62cd\u7167'),
                          ),
                        ),
                      ],
                    ),
                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 86,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final image = selectedImages[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(image.path),
                                    width: 86,
                                    height: 86,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: InkWell(
                                    onTap: isPublishing ? null : () => setSheetState(() => selectedImages.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), shape: BoxShape.circle),
                                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: isPublishing
                            ? null
                            : () async {
                                final tags = tagCtrl.text
                                    .split(RegExp('[,\u{FF0C}]'))
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                                setSheetState(() => isPublishing = true);
                                final ok = await controller.createPost(
                                  title: titleCtrl.text,
                                  content: contentCtrl.text,
                                  tags: tags,
                                  imageFiles: List<XFile>.from(selectedImages),
                                );
                                if (ok && sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                  return;
                                }
                                if (sheetContext.mounted) {
                                  setSheetState(() => isPublishing = false);
                                  final message = controller.errorMessage.value;
                                  Get.snackbar('\u53d1\u5e03\u5931\u8d25', message.isNotEmpty ? message : '\u8bf7\u7a0d\u540e\u91cd\u8bd5');
                                }
                              },
                        child: isPublishing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Text('\u53d1\u5e03'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
