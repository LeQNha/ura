import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Badge hiển thị Rarity — mỗi mức rarity có 1 màu riêng (đồng bộ với
/// AppColors.rarityXxx) để user quét mắt nhận biết ngay không cần đọc
/// chữ, giống cơ chế "độ hiếm" quen thuộc trong game.
class RarityBadge extends StatelessWidget {
  final String rarity;
  final bool compact;

  const RarityBadge({super.key, required this.rarity, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.rarityColor(rarity);
    final label = ObservationRarity.label(rarity);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.diamond_outlined, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
