import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Thanh tìm kiếm nổi trên bản đồ (kiểu Google Maps/Grab) — bo tròn,
/// đổ bóng nhẹ để nổi lên trên nền bản đồ ở mọi loại địa hình/màu tile.
///
/// Bản nâng cấp: thêm viền mảnh + bóng 2 lớp (1 lớp lan rộng rất nhẹ,
/// 1 lớp gần và rõ) để nổi bật trên mọi nền bản đồ mà không bị "nặng";
/// nút filter khi đang bật có gradient + bóng nhuộm màu để trạng thái
/// đang-lọc nhận biết ngay từ xa. Giữ nguyên constructor.
class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final hintColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          Icon(Icons.search_rounded, size: 21, color: hintColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14.5),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc tag...',
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 18, color: hintColor),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: hasActiveFilters ? AppColors.primaryGradient : null,
                  color: hasActiveFilters
                      ? null
                      : AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                  boxShadow: hasActiveFilters
                      ? AppColors.softShadow(
                          opacity: 0.4, blur: 12, offset: const Offset(0, 4))
                      : null,
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color:
                      hasActiveFilters ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
