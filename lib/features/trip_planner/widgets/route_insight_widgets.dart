import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/directions_button.dart';
import '../../ai/models/route_ai_models.dart';
import '../models/trip_plan.dart';

/// Huy hiệu cho biết lộ trình do AI cá nhân hóa hay do bộ lập dự phòng
/// trên máy tạo ra — để người dùng (và hội đồng lúc demo) luôn biết đang
/// xem kết quả của cái gì.
class AiSourceBadge extends StatelessWidget {
  final bool personalized;

  const AiSourceBadge({super.key, required this.personalized});

  @override
  Widget build(BuildContext context) {
    final color = personalized ? AppColors.primary : AppColors.warning;
    final icon = personalized ? Icons.auto_awesome : Icons.phone_android;
    final label =
        personalized ? 'Cá nhân hóa bởi AI' : 'Bộ lập cơ bản (chạy trên máy)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Khung thông báo nhẹ (không phải lỗi).
class RouteNoticeBanner extends StatelessWidget {
  final String message;

  const RouteNoticeBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// "AI hiểu bạn thế nào" — hiển thị hồ sơ sở thích mà server suy ra.
/// Giúp người dùng thấy lộ trình được cá nhân hóa dựa trên cái gì, và
/// minh bạch hóa việc AI "học" từ lựa chọn và lịch sử của chính họ.
class TasteProfileCard extends StatelessWidget {
  final AiTasteProfile profile;

  const TasteProfileCard({super.key, required this.profile});

  String _sourcesText() {
    final parts = <String>[];
    if (profile.sources.contains('explicit')) parts.add('lựa chọn của bạn');
    if (profile.sources.contains('history')) {
      parts.add('bài bạn đã đăng/lưu');
    }
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = profile.confidence.clamp(0.0, 1.0);
    final sourcesText = _sourcesText();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('AI hiểu bạn thế nào',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.coldStart)
            Text(
              'Chưa có đủ thông tin về sở thích của bạn nên AI ưu tiên các '
              'địa điểm được cộng đồng quan tâm. Hãy chọn chủ đề, đăng hoặc '
              'lưu thêm vài địa điểm để lộ trình hợp gu hơn.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in profile.topCategories)
                  _InsightChip(
                    label: '${c.categoryName.isEmpty ? c.categoryId : c.categoryName}'
                        ' ${(c.affinity * 100).round()}%',
                    color: AppColors.primary,
                  ),
                for (final tag in profile.topTags)
                  _InsightChip(label: '#$tag', color: AppColors.info),
              ],
            ),
            if (profile.topCategories.isEmpty && profile.topTags.isEmpty)
              Text(
                'AI chưa nhận ra danh mục nào bạn đặc biệt yêu thích.',
                style: theme.textTheme.bodySmall,
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Độ tin cậy', style: theme.textTheme.labelSmall),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 6,
                    backgroundColor: theme.dividerColor,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(confidence * 100).round()}%',
                  style: theme.textTheme.labelSmall),
            ],
          ),
          if (sourcesText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Dựa trên: $sourcesText',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InsightChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 1 điểm dừng trong danh sách kết quả. Với lộ trình do AI lập, hiển thị
/// thêm độ phù hợp (%) và các lý do chọn điểm này; với bộ lập dự phòng
/// thì các phần đó tự ẩn đi.
class PersonalizedStopTile extends StatelessWidget {
  final int index;
  final TripStop stop;

  const PersonalizedStopTile({
    super.key,
    required this.index,
    required this.stop,
  });

  Color _matchColor(int percent) {
    if (percent >= 70) return AppColors.success;
    if (percent >= 40) return AppColors.primary;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final observation = stop.observation;
    final match = stop.matchPercent;

    final subtitle = StringBuffer(
      'Cách điểm trước ${formatDistance(stop.distanceFromPreviousMeters)} '
      '· ~${formatDuration(stop.walkingTimeFromPrevious)} đi bộ',
    );
    if (stop.arriveAfter != null) {
      subtitle.write(' · đến sau ~${formatDuration(stop.arriveAfter!)}');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${observation.categoryIcon} ${observation.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    if (match != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _matchColor(match).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$match% hợp gu',
                          style: TextStyle(
                            color: _matchColor(match),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle.toString(), style: theme.textTheme.labelSmall),
                if (stop.reasons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final reason in stop.reasons)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.check_circle_outline,
                                size: 13, color: AppColors.success),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(reason,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          DirectionsButton(
            latitude: observation.latitude,
            longitude: observation.longitude,
            compact: true,
          ),
        ],
      ),
    );
  }
}
