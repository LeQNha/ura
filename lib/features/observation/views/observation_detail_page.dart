import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/directions_button.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../community/providers/community_providers.dart';
import '../../community/repositories/community_repository.dart';
import '../../community/widgets/comments_bottom_sheet.dart';
import '../../community/widgets/report_dialog.dart';
import '../../then_and_now/views/then_and_now_page.dart';
import '../models/observation_model.dart';
import '../repositories/observation_repository.dart';
import '../viewmodels/observation_feed_viewmodel.dart';
import '../widgets/category_pill.dart';
import '../widgets/rarity_badge.dart';
import 'edit_observation_page.dart';

/// Observation Detail — layout: Photo Gallery → Title → Category/Rarity →
/// Description → Then&Now → Thông tin (vị trí/thời gian) → Like/Comment/
/// Save → Contributor.
///
/// Bản nâng cấp giao diện:
/// - Gallery có scrim trên/dưới (nút luôn đọc được), bộ đếm ảnh "1/3",
///   nội dung là 1 "tờ giấy" bo góc trượt đè lên mép ảnh.
/// - Thông tin vị trí/thời gian gom vào 1 thẻ với icon trong khối màu.
/// - Hàng Like/Comment/Save là 1 thanh pill; Contributor là 1 thẻ.
/// - Then & Now là thẻ nổi bật thay vì 1 nút viền thường.
/// Toàn bộ logic (like/bookmark/follow/xóa/sửa/báo cáo) giữ nguyên.
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
        loading: () => const LoadingStateWidget(),
        error: (error, _) => ErrorStateWidget(
          message: '$error',
          onRetry: () =>
              ref.invalidate(observationDetailProvider(observationId)),
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'Không tìm thấy Observation này',
      subtitle: 'Có thể nó đã bị xóa hoặc không còn công khai.',
      action: OutlinedButton(
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        child: const Text('Quay lại'),
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
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwner = currentUser?.id == observation.creatorId;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 360,
          backgroundColor: theme.scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          leading: _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          actions: [
            if (isOwner)
              _CircleIconButton(
                icon: Icons.more_horiz_rounded,
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
            collapseMode: CollapseMode.parallax,
            background: _PhotoGallery(
              photos: observation.photos,
              controller: _pageController,
              currentIndex: _photoIndex,
              onPageChanged: (i) => setState(() => _photoIndex = i),
            ),
          ),
          // "Tờ giấy" bo góc trượt đè lên mép dưới ảnh.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(24),
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  observation.title,
                  style: theme.textTheme.headlineMedium?.copyWith(height: 1.15),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CategoryPill(
                      icon: observation.categoryIcon,
                      name: observation.categoryName,
                    ),
                    RarityBadge(rarity: observation.rarity),
                  ],
                ),
                if (observation.description != null &&
                    observation.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    observation.description!,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  ),
                ],
                if (observation.tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: observation.tags
                        .map((t) => _TagChip(label: t))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 22),
                _ThenAndNowCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ThenAndNowPage(
                        oldPhotoUrl: observation.coverPhoto,
                        observationTitle: observation.title,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _SurfaceCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.location_on_rounded,
                        color: AppColors.primary,
                        title: 'Vị trí',
                        subtitle: observation.address ??
                            '${observation.latitude.toStringAsFixed(5)}, '
                                '${observation.longitude.toStringAsFixed(5)}',
                      ),
                      const _SoftDivider(),
                      _InfoRow(
                        icon: Icons.event_rounded,
                        color: AppColors.accent,
                        title: 'Thời điểm quan sát',
                        subtitle: DateFormat('dd/MM/yyyy')
                            .format(observation.observedAt),
                      ),
                      const _SoftDivider(),
                      _InfoRow(
                        icon: Icons.upload_rounded,
                        color: AppColors.rarityRare,
                        title: 'Đăng lúc',
                        subtitle: formatRelativeTime(observation.createdAt),
                      ),
                      const SizedBox(height: 14),
                      DirectionsButton(
                        latitude: observation.latitude,
                        longitude: observation.longitude,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _ActionRow(observation: observation),
                const SizedBox(height: 18),
                _ContributorRow(observation: observation),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showOwnerMenu(BuildContext context, ObservationModel observation) {
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderOf(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.edit_rounded,
              label: 'Chỉnh sửa',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        EditObservationPage(observation: observation),
                  ),
                );
              },
            ),
            _MenuTile(
              icon: Icons.delete_outline_rounded,
              label: 'Xóa',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(ctx);
                await _confirmDelete(context, observation);
              },
            ),
            const SizedBox(height: 8),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error.withOpacity(0.12),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 28),
        ),
        title: const Text('Xóa Observation?'),
        content: const Text(
          'Observation sẽ không còn hiển thị công khai. Hành động này '
          'không thể tự hoàn tác trong app.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
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
    final placeholder = AppColors.surfaceMutedOf(Theme.of(context).brightness);

    if (photos.isEmpty) {
      return Container(
        color: placeholder,
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
                fadeInDuration: const Duration(milliseconds: 220),
                placeholder: (context, url) => Container(color: placeholder),
              ),
            );
          },
        ),
        // Scrim trên để nút trắng luôn đọc được.
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.topScrim),
            ),
          ),
        ),
        if (photos.length > 1) ...[
          Positioned(
            bottom: 40,
            right: 16,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Text(
                  '${currentIndex + 1}/${photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(photos.length, (i) {
                  final active = i == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
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

class _FullscreenGallery extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _FullscreenGallery({required this.photos, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.photos[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              // Khóa chiều cao: nếu không, Center trong _CircleIconButton sẽ
              // giãn hết chiều cao màn hình và chặn thao tác vuốt ảnh.
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (widget.photos.length > 1)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_index + 1}/${widget.photos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút tròn kính tối đặt trên ảnh.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Center(
        child: Material(
          color: Colors.black.withOpacity(0.38),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: Colors.white, size: 21),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent
            .withOpacity(brightness == Brightness.dark ? 0.2 : 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.22)),
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: brightness == Brightness.dark
              ? AppColors.accentLight
              : AppColors.accent,
        ),
      ),
    );
  }
}

/// Khối bề mặt dùng chung — nền surface, viền mảnh, bóng nhẹ.
class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(brightness),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(brightness)),
        boxShadow: AppColors.cardShadow(isDark: brightness == Brightness.dark),
      ),
      child: child,
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: AppColors.borderOf(Theme.of(context).brightness),
      ),
    );
  }
}

class _ThenAndNowCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ThenAndNowCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow(
          tint: AppColors.accent,
          opacity: 0.28,
          blur: 20,
          offset: const Offset(0, 8),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.compare_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Then & Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'So sánh với hiện tại ngay tại chỗ',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 21, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color == AppColors.error ? AppColors.error : null,
        ),
      ),
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

    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _ActionButton(
            icon: isLiked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: '${widget.observation.likeCount}',
            color: isLiked ? AppColors.error : null,
            onTap: _toggleLike,
          ),
          const SizedBox(width: 4),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '${widget.observation.commentCount}',
            onTap: () => showCommentsBottomSheet(
              context,
              observationId: widget.observation.id,
            ),
          ),
          const Spacer(),
          _ActionButton(
            icon: isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: isBookmarked ? 'Đã lưu' : 'Lưu',
            color: isBookmarked ? AppColors.primary : null,
            onTap: _toggleBookmark,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.textTheme.bodyMedium?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: tint),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: tint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributorRow extends ConsumerWidget {
  final ObservationModel observation;

  const _ContributorRow({required this.observation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwnProfile = currentUser?.id == observation.creatorId;

    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => context.push('/profile/${observation.creatorId}'),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surfaceOf(brightness),
                      backgroundImage: observation.creatorAvatarUrl != null
                          ? CachedNetworkImageProvider(
                              observation.creatorAvatarUrl!)
                          : null,
                      child: observation.creatorAvatarUrl == null
                          ? Text(
                              observation.creatorUsername.isNotEmpty
                                  ? observation.creatorUsername[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryTextOf(brightness),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Người đóng góp',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 1),
                        Text(
                          '@${observation.creatorUsername}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
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
      ),
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
    final brightness = Theme.of(context).brightness;
    final isFollowingAsync =
        ref.watch(isFollowingProvider(widget.targetUserId));
    final isFollowing = isFollowingAsync.valueOrNull ?? false;

    if (isFollowing) {
      return OutlinedButton(
        onPressed: _loading ? null : _toggle,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: BorderSide(color: AppColors.borderOf(brightness)),
          foregroundColor: AppColors.textSecondaryOf(brightness),
        ),
        child: const Text('Đang follow', style: TextStyle(fontSize: 12.5)),
      );
    }

    return FilledButton(
      onPressed: _loading ? null : _toggle,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const Text('Follow', style: TextStyle(fontSize: 12.5)),
    );
  }
}
