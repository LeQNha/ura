import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../models/observation_model.dart';
import 'category_pill.dart';
import 'rarity_badge.dart';

/// Card hiển thị 1 Observation trong feed/danh sách — bố cục "editorial":
/// tiêu đề + Category đè lên ảnh (trên lớp scrim), Rarity là nhãn nổi ở
/// góc trên-trái.
///
/// Bản nâng cấp lần 2: viền mảnh + bóng ấm, ảnh cao hơn (đủ chỗ cho
/// tiêu đề), CategoryPill dạng kính tối trên ảnh, footer có avatar viền
/// gradient và 2 chip số liệu (tim/bình luận) thay vì icon rời rạc.
///
/// ⚠️ Giữ nguyên constructor `ObservationCard({observation, onTap})`.
class ObservationCard extends StatelessWidget {
  final ObservationModel observation;
  final VoidCallback onTap;

  const ObservationCard({
    super.key,
    required this.observation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Container ngoài vẽ shadow (không clip), ClipRRect trong lo bo góc.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow(isDark: isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: AppColors.surfaceOf(brightness),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderOf(brightness).withOpacity(0.7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhoto(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                    child: _buildFooter(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    final placeholder = AppColors.surfaceMutedOf(Theme.of(context).brightness);

    return AspectRatio(
      aspectRatio: 1.25,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (observation.coverPhoto.isNotEmpty)
            CachedNetworkImage(
              imageUrl: observation.coverPhoto,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 220),
              placeholder: (context, url) => Container(color: placeholder),
              errorWidget: (context, url, error) => Container(
                color: placeholder,
                child: const Icon(Icons.broken_image_outlined,
                    color: Color(0xFFB8B4AC)),
              ),
            )
          else
            Container(
              color: placeholder,
              child: const Icon(Icons.image_outlined, color: Color(0xFFB8B4AC)),
            ),

          // Scrim trên (cho badge) + scrim dưới (cho tiêu đề).
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x55000000),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xDD000000),
                  ],
                  stops: [0, 0.28, 0.45, 1],
                ),
              ),
            ),
          ),

          Positioned(
            top: 12,
            left: 12,
            child: RarityBadge(rarity: observation.rarity, compact: true),
          ),

          if (observation.photos.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${observation.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            left: 14,
            right: 14,
            bottom: 13,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryPill(
                  icon: observation.categoryIcon,
                  name: observation.categoryName,
                  onImage: true,
                ),
                const SizedBox(height: 9),
                Text(
                  observation.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 21,
                    color: Colors.white,
                    height: 1.15,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(1.6),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.surfaceOf(brightness),
            backgroundImage: observation.creatorAvatarUrl != null
                ? CachedNetworkImageProvider(observation.creatorAvatarUrl!)
                : null,
            child: observation.creatorAvatarUrl == null
                ? Text(
                    observation.creatorUsername.isNotEmpty
                        ? observation.creatorUsername[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTextOf(brightness),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '@${observation.creatorUsername} · ${formatRelativeTime(observation.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.favorite_rounded,
          value: observation.likeCount,
          active: observation.likeCount > 0,
          activeColor: AppColors.error,
        ),
        const SizedBox(width: 6),
        _StatChip(
          icon: Icons.chat_bubble_rounded,
          value: observation.commentCount,
          active: false,
          activeColor: AppColors.info,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final bool active;
  final Color activeColor;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelMedium?.color;
    final tint = active ? activeColor : muted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMutedOf(theme.brightness),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }
}
