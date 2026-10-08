import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Hiển thị Category dạng "pill" gọn (icon + tên) — dùng ở Card và
/// Detail. Tách riêng widget để đảm bảo Category luôn hiển thị nhất
/// quán mọi nơi trong app, chỉ cần sửa 1 chỗ nếu muốn đổi style sau này.
///
/// Bản nâng cấp: icon nằm trong khối tròn nền trắng nổi lên trên nền
/// pill (giống nhãn dán 2 lớp), viền mảnh thay vì chỉ đổ màu phẳng —
/// giữ nguyên constructor `CategoryPill({icon, name})`.
class CategoryPill extends StatelessWidget {
  final String icon;
  final String name;

  const CategoryPill({super.key, required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
