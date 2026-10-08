import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../models/observation_model.dart';
import 'category_pill.dart';
import 'rarity_badge.dart';

/// Card hiển thị 1 Observation trong feed/danh sách.
///
/// Bản nâng cấp: chuyển sang bố cục kiểu "editorial/tạp chí" — tiêu đề
/// và Category đặt ĐÈ LÊN ảnh (trên lớp gradient scrim để luôn đọc
/// được dù ảnh sáng/tối), Rarity đóng vai trò 1 "nhãn specimen" nổi ở
/// góc trên-trái ảnh thay vì nằm chung hàng với Category bên dưới như
/// trước — ảnh trở thành yếu tố chủ đạo, đúng tinh thần "field journal"
/// nhưng có chiều sâu/độ hoàn thiện cao hơn bản pill phẳng cũ.
///
/// ⚠️ Giữ nguyên constructor `ObservationCard({observation, onTap})` —
/// không đổi field nào của [ObservationModel] được dùng, chỉ đổi cách
/// trình bày.
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
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    // Outer Container vẽ shadow (KHÔNG clip) + ClipRRect bên trong lo
    // phần bo góc nội dung — tách 2 việc ra để shadow luôn hiện đủ,
    // không bị clip mất theo bo góc (lỗi thường gặp khi gộp chung 1 widget).
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow(
          tint: isDark ? Colors.black : AppColors.textPrimaryLight,
          opacity: isDark ? 0.35 : 0.08,
          blur: 22,
          offset: const Offset(0, 10),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: surface,
          child: InkWell(
            onTap: onTap,
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

          // Lớp gradient để chữ đè lên luôn đọc được, bất kể ảnh sáng
          // hay tối màu ở nửa dưới.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
          ),

          // Rarity nổi như 1 nhãn specimen ở góc trên-trái.
          Positioned(
            top: 12,
            left: 12,
            child: RarityBadge(rarity: observation.rarity, compact: true),
          ),

          // Đếm số ảnh — chỉ hiện khi có nhiều hơn 1.
          if (observation.photos.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Category + Title đè lên đáy ảnh, trên lớp gradient.
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoryPill(
                  icon: observation.categoryIcon,
                  name: observation.categoryName,
                ),
                const SizedBox(height: 8),
                Text(
                  observation.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 19,
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
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '@${observation.creatorUsername} · ${formatRelativeTime(observation.createdAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.favorite_rounded,
            size: 15,
            color: observation.likeCount > 0
                ? AppColors.error.withOpacity(0.75)
                : Theme.of(context).textTheme.labelMedium?.color),
        const SizedBox(width: 3),
        Text('${observation.likeCount}',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 12),
        Icon(Icons.chat_bubble_rounded,
            size: 13, color: Theme.of(context).textTheme.labelMedium?.color),
        const SizedBox(width: 3),
        Text('${observation.commentCount}',
            style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
