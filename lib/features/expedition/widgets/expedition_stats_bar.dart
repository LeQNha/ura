import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';

/// Hàng 3 chỉ số của 1 Expedition — dùng chung cho màn theo dõi trực
/// tiếp (đang thám hiểm, duration được tính lại mỗi giây từ bên ngoài)
/// và Summary (giá trị cố định sau khi kết thúc).
class ExpeditionStatsBar extends StatelessWidget {
  final Duration duration;
  final double distanceMeters;
  final int observationCount;

  const ExpeditionStatsBar({
    super.key,
    required this.duration,
    required this.distanceMeters,
    required this.observationCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: Icons.timer_outlined,
            value: formatDuration(duration),
            label: 'Thời gian',
          ),
        ),
        Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
        Expanded(
          child: _StatItem(
            icon: Icons.route_outlined,
            value: formatDistance(distanceMeters),
            label: 'Quãng đường',
          ),
        ),
        Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
        Expanded(
          child: _StatItem(
            icon: Icons.camera_alt_outlined,
            value: '$observationCount',
            label: 'Ghi nhận',
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
