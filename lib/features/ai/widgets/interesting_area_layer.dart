import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../models/ai_models.dart';
import '../providers/ai_providers.dart';

/// Lớp vẽ các "khu vực thú vị" (do DBSCAN gom cụm) lên bản đồ, dạng
/// vòng tròn mờ có bán kính thật tính bằng mét.
///
/// Đặt lớp này TRƯỚC (bên dưới) lớp marker trong danh sách `children`
/// của FlutterMap, để vòng tròn không che mất marker.
///
/// Trả về widget rỗng khi tính năng đang tắt hoặc chưa có kết quả —
/// nên có thể thả thẳng vào `children` mà không cần kiểm tra điều kiện
/// ở nơi gọi.
class InterestingAreaLayer extends ConsumerWidget {
  const InterestingAreaLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(interestingAreasProvider).valueOrNull ?? [];
    if (areas.isEmpty) return const SizedBox.shrink();

    return CircleLayer(
      circles: areas.map((area) {
        // Màu đậm dần theo điểm thú vị — khu vực càng đáng khám phá
        // thì càng nổi bật, nhìn lướt qua bản đồ là thấy ngay.
        final intensity = area.score.clamp(0.0, 1.0);
        return CircleMarker(
          point: LatLng(area.centerLatitude, area.centerLongitude),
          radius: area.radiusMeters,
          useRadiusInMeter: true,
          color: AppColors.primary.withOpacity(0.10 + intensity * 0.18),
          borderColor: AppColors.primary.withOpacity(0.35 + intensity * 0.35),
          borderStrokeWidth: 2,
        );
      }).toList(),
    );
  }
}

/// Nút bật/tắt lớp "Khu vực thú vị", đặt nổi trên bản đồ.
class InterestingAreaToggle extends ConsumerWidget {
  const InterestingAreaToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(showInterestingAreasProvider);
    final isLoading =
        enabled && ref.watch(interestingAreasProvider).isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        boxShadow: AppColors.neutralShadow(
          opacity: 0.12,
          blur: 14,
          offset: const Offset(0, 4),
        ),
      ),
      child: IconButton(
        tooltip: 'Khu vực thú vị (AI)',
        onPressed: () => ref
            .read(showInterestingAreasProvider.notifier)
            .update((state) => !state),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(
                enabled
                    ? Icons.blur_on_rounded
                    : Icons.blur_circular_outlined,
                color:
                    enabled ? AppColors.primary : AppColors.textSecondaryLight,
              ),
      ),
    );
  }
}

/// Bảng tóm tắt các khu vực thú vị — mở bằng bottom sheet, cho xem
/// danh sách xếp hạng thay vì chỉ nhìn vòng tròn trên bản đồ.
Future<void> showInterestingAreasSheet(
  BuildContext context, {
  required List<InterestingArea> areas,
  required void Function(InterestingArea area) onAreaTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDAD7D0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Text('Khu vực thú vị',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Do thuật toán gom cụm tự tìm ra, xếp theo mật độ phát hiện, '
                'độ đa dạng danh mục và độ hiếm.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.45),
              ),
            ),
            if (areas.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Text(
                  'Chưa tìm thấy khu vực nào — cần thêm phát hiện tập trung '
                  'gần nhau, hoặc kiểm tra AI server đã chạy chưa.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              )
            else
              ...areas.asMap().entries.map((entry) {
                final index = entry.key;
                final area = entry.value;
                return ListTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    onAreaTap(area);
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    area.tierLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${area.observationCount} phát hiện · '
                    '${area.distinctCategories} danh mục · '
                    'bán kính ${area.radiusMeters.round()}m',
                    style: Theme.of(ctx).textTheme.labelSmall,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                );
              }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
