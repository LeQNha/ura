import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Thanh tìm kiếm nổi trên bản đồ (kiểu Google Maps/Grab) — bo tròn,
/// đổ bóng nhẹ để nổi lên trên nền bản đồ ở mọi loại địa hình/màu tile.
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

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, size: 20, color: AppColors.textSecondaryLight),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc tag...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasActiveFilters
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tune,
                  size: 18,
                  color: hasActiveFilters ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
