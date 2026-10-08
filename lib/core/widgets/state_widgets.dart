import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Bộ 3 widget trạng thái dùng chung — chuẩn hóa cách hiển thị
/// Empty/Error/Loading thay vì mỗi màn tự viết 1 kiểu riêng lẻ.
///
/// Bản nâng cấp giao diện: icon đặt trong khối tròn có gradient nhẹ +
/// vòng viền (thay icon xám trần), chữ có nhịp rõ ràng hơn, thêm giới
/// hạn chiều rộng để dòng mô tả không trải quá dài trên màn rộng.
/// KHÔNG đổi constructor của cả 3 widget — mọi nơi đang dùng vẫn chạy
/// nguyên vẹn.

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StateIconHalo(icon: icon, tint: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(height: 1.5),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _StateIconHalo(
                icon: Icons.cloud_off_rounded,
                tint: AppColors.error,
              ),
              const SizedBox(height: 20),
              Text(
                'Đã có lỗi xảy ra',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(height: 1.5),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Khối tròn chứa icon cho các state — gradient nhẹ + 2 lớp viền tạo
/// cảm giác "huy hiệu" thay vì icon trần trên nền trắng.
class _StateIconHalo extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const _StateIconHalo({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withOpacity(0.16), tint.withOpacity(0.04)],
        ),
        border: Border.all(color: tint.withOpacity(0.22), width: 1.2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tint.withOpacity(0.12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 30, color: tint),
      ),
    );
  }
}
