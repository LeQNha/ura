import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Nút CTA chính dạng gradient — dùng cho hành động quan trọng nhất của
/// mỗi màn (Đăng nhập, Đăng ký, Nhận thưởng...). Có trạng thái loading
/// và disabled (mờ đi) thống nhất.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Gradient gradient;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient = AppColors.primaryGradient,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final tint = gradient == AppColors.accentGradient
        ? AppColors.accent
        : AppColors.primary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: onPressed == null && !isLoading ? 0.5 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? AppColors.softShadow(
                  tint: tint,
                  opacity: 0.30,
                  blur: 18,
                  offset: const Offset(0, 8),
                )
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 19, color: Colors.white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
