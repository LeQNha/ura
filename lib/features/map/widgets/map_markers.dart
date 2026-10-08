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
///
/// Bản nâng cấp: thêm quầng sáng mờ phía sau (halo) theo màu rarity +
/// gradient trên thân marker + bóng nhuộm màu — marker hiếm sẽ "phát
/// sáng" rõ hơn marker thường, tăng sức hút thị giác mà vẫn giữ đúng
/// quy ước màu cũ. Giữ nguyên constructor.
class ObservationMarkerIcon extends StatelessWidget {
  final ObservationModel observation;

  const ObservationMarkerIcon({super.key, required this.observation});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(observation.rarity);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Quầng sáng mờ phía sau — càng hiếm màu càng nổi, tạo cảm
        // giác "toả sáng" trên nền bản đồ.
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.22),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, 0.28) ?? color,
                  color,
                ],
              ),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              observation.categoryIcon,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bubble hiển thị khi nhiều marker gần nhau được gộp lại (cluster) —
/// hiển thị số lượng Observation trong cụm đó.
///
/// Bản nâng cấp: 2 lớp vòng (vòng ngoài mờ + lõi gradient) thay vì 1
/// vòng đặc phẳng, giúp cụm marker trông có chiều sâu và dễ phân biệt
/// với marker đơn lẻ hơn.
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
        color: AppColors.primary.withOpacity(0.25),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size - 7,
        height: size - 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: AppColors.softShadow(
            opacity: 0.45,
            blur: 10,
            offset: const Offset(0, 4),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
