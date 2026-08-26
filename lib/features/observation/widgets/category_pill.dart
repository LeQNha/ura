import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Hiển thị Category dạng "pill" gọn (icon + tên) — dùng ở Card và
/// Detail. Tách riêng widget để đảm bảo Category luôn hiển thị nhất
/// quán mọi nơi trong app, chỉ cần sửa 1 chỗ nếu muốn đổi style sau này.
class CategoryPill extends StatelessWidget {
  final String icon;
  final String name;

  const CategoryPill({super.key, required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
