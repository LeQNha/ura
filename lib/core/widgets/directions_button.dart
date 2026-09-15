import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/directions_utils.dart';

/// Nút "Chỉ đường" tái sử dụng — thả vào bất kỳ màn nào có sẵn tọa độ
/// (Observation Detail, popup marker trên Map/Scanner, chip địa điểm
/// đã tìm...) mà không cần viết lại logic mở Google Maps mỗi lần.
///
/// [compact] = true → chỉ hiện icon tròn nhỏ (hợp với popup/card chật
/// chỗ). [compact] = false (mặc định) → nút full-width có label, hợp
/// đặt trong 1 form/detail page.
class DirectionsButton extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool compact;

  const DirectionsButton({
    super.key,
    required this.latitude,
    required this.longitude,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    void handleTap() => openDirectionsTo(
          context,
          latitude: latitude,
          longitude: longitude,
        );

    if (compact) {
      return InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions, size: 20, color: AppColors.primary),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: handleTap,
        icon: const Icon(Icons.directions, size: 18),
        label: const Text('Chỉ đường'),
      ),
    );
  }
}
