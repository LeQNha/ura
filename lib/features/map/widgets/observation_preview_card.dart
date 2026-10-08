import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../observation/models/observation_model.dart';
import '../../observation/widgets/category_pill.dart';
import '../../observation/widgets/rarity_badge.dart';
import '../../../core/widgets/directions_button.dart';

/// Card ngang hiện lên (dạng bottom sheet nhỏ) khi bấm vào 1 marker trên
/// Map — cho xem nhanh thông tin trước khi quyết định mở Detail đầy đủ,
/// giữ người dùng ở lại bản đồ nếu chỉ đang "lướt" xem xung quanh.
///
/// Bản nâng cấp: thêm thanh kéo (grab handle) cho đúng ngôn ngữ bottom
/// sheet, ảnh vuông bo góc mềm hơn + viền mảnh, chip khoảng cách tách
/// riêng thành khối nền nhẹ (dễ quét mắt hơn dòng chữ xám), và 1 dòng
/// gợi ý hành động ở dưới. Giữ nguyên constructor + mọi hành vi
/// (onTap card, nút Chỉ đường riêng).
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
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDAD7D0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.neutralShadow(
                        opacity: 0.12,
                        blur: 10,
                        offset: const Offset(0, 4),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 82,
                        height: 82,
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
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          observation.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 15.5, height: 1.25),
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
                            RarityBadge(
                                rarity: observation.rarity, compact: true),
                          ],
                        ),
                        if (distanceInMeters != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.near_me_rounded,
                                        size: 12, color: AppColors.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatDistance(distanceInMeters!),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '@${observation.creatorUsername}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      DirectionsButton(
                        latitude: observation.latitude,
                        longitude: observation.longitude,
                        compact: true,
                      ),
                      const SizedBox(height: 6),
                      Icon(Icons.chevron_right_rounded,
                          color:
                              Theme.of(context).textTheme.labelMedium?.color),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
