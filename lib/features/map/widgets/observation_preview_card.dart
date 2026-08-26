import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../observation/models/observation_model.dart';
import '../../observation/widgets/category_pill.dart';
import '../../observation/widgets/rarity_badge.dart';

/// Card ngang hiện lên (dạng bottom sheet nhỏ) khi bấm vào 1 marker trên
/// Map — cho xem nhanh thông tin trước khi quyết định mở Detail đầy đủ,
/// giữ người dùng ở lại bản đồ nếu chỉ đang "lướt" xem xung quanh.
class ObservationPreviewCard extends StatelessWidget {
  final ObservationModel observation;
  final double? distanceInMeters;
  final VoidCallback onTap;

  const ObservationPreviewCard({
    super.key,
    required this.observation,
    required this.onTap,
    this.distanceInMeters,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: observation.coverPhoto.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: observation.coverPhoto,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: const Color(0xFFEDEAE3)),
                      )
                    : Container(
                        color: const Color(0xFFEDEAE3),
                        child: const Icon(Icons.image_outlined,
                            color: Color(0xFFB8B4AC)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    observation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 6),
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
                  if (distanceInMeters != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.near_me_outlined,
                            size: 13, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          '${formatDistance(distanceInMeters!)} · @${observation.creatorUsername}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}
