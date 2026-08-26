import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
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
    final observationAsync = ref.watch(observationDetailProvider(observationId));

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
          const Icon(Icons.search_off, size: 48, color: AppColors.textSecondaryLight),
          const SizedBox(height: 12),
          const Text('Không tìm thấy Observation này.'),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
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
                onTap: () => _showComingSoon('Report'),
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
              title: const Text('Xóa', style: TextStyle(color: AppColors.error)),
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

class _ContributorRow extends StatelessWidget {
  final ObservationModel observation;

  const _ContributorRow({required this.observation});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          backgroundImage: observation.creatorAvatarUrl != null
              ? CachedNetworkImageProvider(observation.creatorAvatarUrl!)
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
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              Text(
                '@${observation.creatorUsername}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
