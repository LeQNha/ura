import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Hiển thị Category dạng "pill" gọn (icon + tên) — dùng ở Card và Detail.
///
/// [onImage] = true khi pill nằm ĐÈ LÊN ảnh: dùng nền kính tối + chữ trắng
/// để luôn đọc được (bản cũ dùng chữ amber đậm trên nền ảnh tối nên rất
/// khó đọc). Mặc định false → kiểu nhãn amber nhạt cho nền thường.
///
/// Giữ nguyên constructor cũ `CategoryPill({icon, name})`; `onImage` là
/// tham số tùy chọn.
class CategoryPill extends StatelessWidget {
  final String icon;
  final String name;
  final bool onImage;

  const CategoryPill({
    super.key,
    required this.icon,
    required this.name,
    this.onImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor =
        onImage ? Colors.white : AppColors.primaryTextOf(brightness);

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: onImage
            ? Colors.black.withOpacity(0.42)
            : AppColors.primary
                .withOpacity(brightness == Brightness.dark ? 0.16 : 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: onImage
              ? Colors.white.withOpacity(0.28)
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
