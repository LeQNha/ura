import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../observation/models/observation_model.dart';

/// Marker của 1 Observation hiển thị đè lên camera preview trong Urban
/// Scanner — giống HUD (heads-up display) trong game, không phải pin
/// bản đồ thông thường. Càng gần thì marker càng to/rõ (hiệu ứng chiều
/// sâu đơn giản dựa trên khoảng cách), càng xa thì càng nhỏ/mờ.
class ArMarkerWidget extends StatelessWidget {
  final ObservationModel observation;
  final double distanceMeters;
  final double depthScale; // 0.4 (xa) .. 1.0 (gần)
  final VoidCallback onTap;

  const ArMarkerWidget({
    super.key,
    required this.observation,
    required this.distanceMeters,
    required this.depthScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(observation.rarity);
    final opacity = (0.55 + depthScale * 0.45).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: depthScale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  observation.categoryIcon,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatDistance(distanceMeters),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
