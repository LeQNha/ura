import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Badge hiển thị Rarity — thiết kế theo hướng "con dấu/nhãn tem"
/// (specimen tag) thay vì pill phẳng thông thường: 1 chấm tròn đặc màu
/// (như dấu niêm phong) + nhãn chữ hoa dãn cách, viền + nền gradient
/// nhẹ theo màu rarity, có bóng đổ nhuộm màu để tạo chiều sâu — giúp
/// mắt vẫn nhận biết ngay theo màu (giữ đúng hành vi cũ), nhưng trông
/// "được thiết kế" hơn thay vì 1 pill bo tròn chung chung.
///
/// ⚠️ Giữ nguyên constructor `RarityBadge({rarity, compact})` — nhiều
/// màn khác (ObservationCard, Detail, Create/Edit, Map preview) đang
/// gọi đúng 2 tham số này, không đổi tên/thêm tham số bắt buộc.
class RarityBadge extends StatelessWidget {
  final String rarity;
  final bool compact;

  const RarityBadge({super.key, required this.rarity, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(rarity);
    final label = ObservationRarity.label(rarity);
    final dotSize = compact ? 14.0 : 17.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 11,
        vertical: compact ? 3.5 : 5.5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.16), color.withOpacity(0.06)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45), width: 1),
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_awesome,
              size: compact ? 8 : 10,
              color: Colors.white,
            ),
          ),
          SizedBox(width: compact ? 5 : 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
