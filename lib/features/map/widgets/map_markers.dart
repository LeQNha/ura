import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../observation/models/observation_model.dart';

/// Marker của 1 Observation trên bản đồ.
///
/// Thiết kế: hình tròn màu theo Rarity (không phải theo Category) —
/// giúp mắt user quét được ngay "chỗ nào có phát hiện hiếm" khi nhìn
/// toàn bản đồ, giống cơ chế loot rarity quen thuộc trong game — đúng
/// tinh thần gamification xuyên suốt app. Icon Category nằm bên trong
/// để vẫn phân biệt được loại khi zoom gần.
class ObservationMarkerIcon extends StatelessWidget {
  final ObservationModel observation;

  const ObservationMarkerIcon({super.key, required this.observation});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(observation.rarity);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        observation.categoryIcon,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

/// Bubble hiển thị khi nhiều marker gần nhau được gộp lại (cluster) —
/// hiển thị số lượng Observation trong cụm đó.
class ClusterBubble extends StatelessWidget {
  final int count;

  const ClusterBubble({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    // Bubble to dần theo số lượng bên trong (giới hạn để không phá layout)
    // — giúp phân biệt trực quan cụm nhỏ và cụm lớn ngay từ cái nhìn đầu.
    final size = 36.0 + (count.clamp(0, 50) / 50) * 16;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
