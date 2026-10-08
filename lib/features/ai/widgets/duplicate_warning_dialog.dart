import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../observation/models/observation_model.dart';
import '../models/ai_models.dart';

/// Hiện cảnh báo khi AI nghi ngờ ảnh vừa chụp trùng với 1 Observation
/// đã có gần đó.
///
/// Trả về `true` nếu người dùng vẫn muốn đăng, `false` nếu huỷ.
///
/// **Quyết định thiết kế quan trọng:** đây là *cảnh báo*, KHÔNG phải
/// *chặn*. AI không hoàn hảo — có thể nhầm 2 cánh cửa cũ giống nhau
/// thành một, hoặc bỏ sót. Người dùng đang đứng tại hiện trường mới là
/// người biết rõ nhất, nên quyền quyết định cuối cùng thuộc về họ.
Future<bool> showDuplicateWarningDialog(
  BuildContext context, {
  required DuplicateCheckResult result,
  required ObservationModel? existingObservation,
}) async {
  final match = result.bestMatch;
  if (match == null) return true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.copy_rounded,
                color: AppColors.warning, size: 21),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Có thể đã được ghi nhận')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ảnh của bạn giống khoảng ${match.similarityPercent}% với một '
            'phát hiện đã có gần đây.',
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (existingObservation != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(ctx).dividerColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: existingObservation.coverPhoto.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: existingObservation.coverPhoto,
                              fit: BoxFit.cover,
                            )
                          : Container(color: const Color(0xFFEDEAE3)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingObservation.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${existingObservation.creatorUsername}',
                          style: Theme.of(ctx).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Nếu đây thực sự là một phát hiện khác, bạn vẫn có thể đăng bình thường.',
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.5),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Để tôi xem lại'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: const Text('Vẫn đăng'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
