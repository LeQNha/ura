import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../models/observation_model.dart';
import 'category_pill.dart';
import 'rarity_badge.dart';

/// Card hiển thị 1 Observation trong feed/danh sách.
///
/// Hướng thiết kế: giống một "trang nhật ký thực địa" hơn là một bài
/// post mạng xã hội — ảnh lớn chiếm phần trên, rarity đóng vai trò như
/// một con dấu/nhãn dán ở góc ảnh, phần thông tin bên dưới có nhịp rõ
/// ràng (title serif nổi bật → category/rarity → meta hàng dưới cùng).
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhoto(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    observation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      CategoryPill(
                        icon: observation.categoryIcon,
                        name: observation.categoryName,
                      ),
                      RarityBadge(rarity: observation.rarity, compact: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (observation.coverPhoto.isNotEmpty)
            CachedNetworkImage(
              imageUrl: observation.coverPhoto,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: const Color(0xFFEDEAE3),
              ),
              errorWidget: (context, url, error) => Container(
                color: const Color(0xFFEDEAE3),
                child: const Icon(Icons.broken_image_outlined,
                    color: Color(0xFFB8B4AC)),
              ),
            )
          else
            Container(
              color: const Color(0xFFEDEAE3),
              child: const Icon(Icons.image_outlined, color: Color(0xFFB8B4AC)),
            ),

          // Đếm số ảnh — chỉ hiện khi có nhiều hơn 1, giống chỉ báo
          // gallery quen thuộc, không cần swipe ngay trên card.
          if (observation.photos.length > 1)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '@${observation.creatorUsername} · ${formatRelativeTime(observation.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Icon(Icons.favorite_border,
            size: 15, color: Theme.of(context).textTheme.labelMedium?.color),
        const SizedBox(width: 3),
        Text('${observation.likeCount}',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 10),
        Icon(Icons.chat_bubble_outline,
            size: 14, color: Theme.of(context).textTheme.labelMedium?.color),
        const SizedBox(width: 3),
        Text('${observation.commentCount}',
            style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
