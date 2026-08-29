import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../community/providers/community_providers.dart';
import '../../community/repositories/community_repository.dart';
import '../../community/widgets/comments_bottom_sheet.dart';
import '../../community/widgets/report_dialog.dart';
import '../models/observation_model.dart';
import '../repositories/observation_repository.dart';
import '../viewmodels/observation_feed_viewmodel.dart';
import '../widgets/category_pill.dart';
import '../widgets/rarity_badge.dart';

/// Observation Detail — theo đúng layout đã chốt ở tài liệu 8.4:
/// Photo Gallery → Title → Category/Rarity → Description → Location →
/// Date/Time → Contributor → Like/Comment/Save.
///
/// Like/Comment/Save ở Phase 1 hiển thị ĐÚNG vị trí/hình dạng như mockup
/// nhưng CHƯA hoạt động thật (chưa có Community system) — bấm vào sẽ
/// báo "sẽ có ở phase sau" thay vì giả vờ hoạt động. Làm giao diện đầy
/// đủ ngay từ bây giờ giúp phase Community sau này chỉ cần nối logic
/// vào, không phải build lại UI.
class ObservationDetailPage extends ConsumerWidget {
  final String observationId;

  const ObservationDetailPage({super.key, required this.observationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observationAsync =
        ref.watch(observationDetailProvider(observationId));

    return Scaffold(
      body: observationAsync.when(
        data: (observation) {
          if (observation == null) {
            return const _NotFoundView();
          }
          return _DetailContent(observation: observation);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off,
              size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          const Text('Không tìm thấy Observation này.'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  final ObservationModel observation;

  const _DetailContent({required this.observation});

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  final _pageController = PageController();
  int _photoIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature sẽ có ở phase Community sắp tới.')),
    );
  }

  Future<void> _handleReport(
    BuildContext context,
    ObservationModel observation,
  ) async {
    final success = await showReportDialog(
      context,
      ref: ref,
      observationId: observation.id,
      observationTitle: observation.title,
    );
    if (context.mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi báo cáo. Cảm ơn bạn!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final observation = widget.observation;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwner = currentUser?.id == observation.creatorId;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 340,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          actions: [
            if (isOwner)
              _CircleIconButton(
                icon: Icons.more_horiz,
                onTap: () => _showOwnerMenu(context, observation),
              )
            else
              _CircleIconButton(
                icon: Icons.flag_outlined,
                onTap: () => _handleReport(context, observation),
              ),
            const SizedBox(width: 12),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _PhotoGallery(
              photos: observation.photos,
              controller: _pageController,
              currentIndex: _photoIndex,
              onPageChanged: (i) => setState(() => _photoIndex = i),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(observation.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CategoryPill(
                        icon: observation.categoryIcon,
                        name: observation.categoryName),
                    RarityBadge(rarity: observation.rarity),
                  ],
                ),
                if (observation.description != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    observation.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                  ),
                ],
                if (observation.tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: observation.tags
                        .map((t) => Chip(label: Text('#$t')))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Vị trí',
                  subtitle: observation.address ??
                      '${observation.latitude.toStringAsFixed(5)}, '
                          '${observation.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.event_outlined,
                  title: 'Thời điểm quan sát',
                  subtitle:
                      DateFormat('dd/MM/yyyy').format(observation.observedAt),
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.upload_outlined,
                  title: 'Đăng lúc',
                  subtitle: formatRelativeTime(observation.createdAt),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _ActionRow(observation: observation),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _ContributorRow(observation: observation),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOwnerMenu(BuildContext context, ObservationModel observation) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Navigator.pop(ctx);
                _showComingSoon('Chỉnh sửa Observation');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title:
                  const Text('Xóa', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                await _confirmDelete(context, observation);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ObservationModel observation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Observation?'),
        content: const Text(
          'Observation sẽ không còn hiển thị công khai. Hành động này '
          'không thể tự hoàn tác trong app.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(observationRepositoryProvider)
          .softDeleteObservation(observation.id);
      if (context.mounted) {
        context.canPop() ? context.pop() : context.go('/home');
      }
    }
  }
}

class _PhotoGallery extends StatelessWidget {
  final List<String> photos;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _PhotoGallery({
    required this.photos,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Container(
        color: const Color(0xFFEDEAE3),
        child: const Icon(Icons.image_outlined,
            size: 48, color: Color(0xFFB8B4AC)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: controller,
          itemCount: photos.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _openFullscreen(context, index),
              child: CachedNetworkImage(
                imageUrl: photos[index],
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: const Color(0xFFEDEAE3)),
              ),
            );
          },
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (i) {
                final active = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenGallery(photos: photos, initialIndex: initialIndex);
        },
      ),
    );
  }
}

class _FullscreenGallery extends StatelessWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullscreenGallery({required this.photos, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: photos[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.4),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends ConsumerStatefulWidget {
  final ObservationModel observation;

  const _ActionRow({required this.observation});

  @override
  ConsumerState<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends ConsumerState<_ActionRow> {
  bool _liking = false;
  bool _bookmarking = false;

  Future<void> _toggleLike() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null || _liking) return;

    setState(() => _liking = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .toggleLike(widget.observation.id, currentUser.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null || _bookmarking) return;

    setState(() => _bookmarking = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .toggleBookmark(currentUser.id, widget.observation.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _bookmarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLikedAsync = ref.watch(isLikedProvider(widget.observation.id));
    final isLiked = isLikedAsync.valueOrNull ?? false;
    final isBookmarkedAsync =
        ref.watch(isBookmarkedProvider(widget.observation.id));
    final isBookmarked = isBookmarkedAsync.valueOrNull ?? false;

    return Row(
      children: [
        InkWell(
          onTap: _toggleLike,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.error : null,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text('${widget.observation.likeCount}'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        InkWell(
          onTap: () => showCommentsBottomSheet(
            context,
            observationId: widget.observation.id,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 20),
                const SizedBox(width: 6),
                Text('${widget.observation.commentCount}'),
              ],
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: _toggleBookmark,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.primary : null,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContributorRow extends ConsumerWidget {
  final ObservationModel observation;

  const _ContributorRow({required this.observation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwnProfile = currentUser?.id == observation.creatorId;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => context.push('/profile/${observation.creatorId}'),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: observation.creatorAvatarUrl != null
                      ? CachedNetworkImageProvider(
                          observation.creatorAvatarUrl!)
                      : null,
                  child: observation.creatorAvatarUrl == null
                      ? Text(
                          observation.creatorUsername.isNotEmpty
                              ? observation.creatorUsername[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Người đóng góp',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight)),
                      Text(
                        '@${observation.creatorUsername}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isOwnProfile)
          _MiniFollowButton(targetUserId: observation.creatorId),
      ],
    );
  }
}

class _MiniFollowButton extends ConsumerStatefulWidget {
  final String targetUserId;

  const _MiniFollowButton({required this.targetUserId});

  @override
  ConsumerState<_MiniFollowButton> createState() => _MiniFollowButtonState();
}

class _MiniFollowButtonState extends ConsumerState<_MiniFollowButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null || _loading) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .toggleFollow(currentUser.id, widget.targetUserId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowingAsync =
        ref.watch(isFollowingProvider(widget.targetUserId));
    final isFollowing = isFollowingAsync.valueOrNull ?? false;

    return OutlinedButton(
      onPressed: _loading ? null : _toggle,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: BorderSide(
          color:
              isFollowing ? Theme.of(context).dividerColor : AppColors.primary,
        ),
        foregroundColor:
            isFollowing ? AppColors.textSecondaryLight : AppColors.primary,
      ),
      child: Text(isFollowing ? 'Đang follow' : 'Follow',
          style: const TextStyle(fontSize: 12)),
    );
  }
}
