import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Splash Screen — hiển thị trong lúc app khởi tạo.
///
/// Router (app_router.dart) sẽ tự động điều hướng sang /login hoặc /home
/// dựa vào authStateChangesProvider ngay khi Firebase xác định được trạng
/// thái đăng nhập, nên màn hình này không cần tự xử lý điều hướng.
///
/// Bản nâng cấp: nền gradient (thay flat color) + emblem tròn kiểu
/// "con dấu địa lý" cho icon la bàn, thêm vài vòng tròn trang trí mờ
/// phía sau tạo chiều sâu — vẫn là StatelessWidget thuần, không thêm
/// logic điều hướng nào (Router vẫn lo phần đó như cũ).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          children: [
            // Vòng tròn trang trí mờ phía sau — gợi cảm giác bản đồ/la
            // bàn, không phải trang trí ngẫu nhiên.
            Positioned(
              top: -60,
              right: -60,
              child: _decorRing(220),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: _decorRing(260),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 1.4,
                      ),
                    ),
                    child: const Icon(
                      Icons.explore_outlined,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore the city. Discover what others overlook.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.2,
                        ),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorRing(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 24),
      ),
    );
  }
}
