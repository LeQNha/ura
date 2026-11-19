import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

/// Dải header gradient dùng chung cho Đăng nhập / Đăng ký / Quên mật khẩu.
///
/// Gồm: nền gradient bo 2 góc dưới, các vòng tròn trang trí mờ (gợi la
/// bàn/bản đồ), huy hiệu icon, tiêu đề serif + mô tả. Với [showBack] sẽ
/// hiện nút quay lại dạng kính mờ.
class AuthHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showBack;

  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          child: Stack(
            children: [
              Positioned(top: -70, right: -50, child: _ring(210, 22)),
              Positioned(bottom: -60, left: -40, child: _ring(150, 18)),
              Positioned(top: 40, left: -30, child: _ring(80, 10)),
              Padding(
                padding: EdgeInsets.fromLTRB(24, topInset + 16, 24, 62),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 44,
                      child: showBack
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: _GlassBackButton(
                                onTap: () => context.canPop()
                                    ? context.pop()
                                    : context.go('/login'),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                          width: 1.3,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.92),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _ring(double size, double width) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.12), width: width),
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withOpacity(0.4)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Thẻ chứa form — nổi lên đè lên đáy header (kéo lên bằng translate),
/// nền surface + bóng mềm. Dùng bọc phần form ở các màn xác thực.
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Transform.translate(
      offset: const Offset(0, -34),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(brightness),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.borderOf(brightness)),
          boxShadow:
              AppColors.cardShadow(isDark: brightness == Brightness.dark),
        ),
        child: child,
      ),
    );
  }
}
