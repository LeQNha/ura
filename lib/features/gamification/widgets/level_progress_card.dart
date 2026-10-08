import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../utils/level_utils.dart';

/// Card hiển thị Level hiện tại + progress bar đến Level kế tiếp.
///
/// Bản nâng cấp: huy hiệu Level dạng 2 vòng đồng tâm (vòng tiến độ
/// chạy quanh số Level, thay vì chỉ 1 vòng tròn tĩnh), thanh XP có
/// hiệu ứng chuyển động khi giá trị đổi, thêm vòng trang trí mờ phía
/// sau và % hoàn thành — giữ nguyên constructor
/// `LevelProgressCard({xp, level})`.
class LevelProgressCard extends StatelessWidget {
  final int xp;
  final int level;

  const LevelProgressCard({super.key, required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    final progress = levelProgress(xp, level);
    final nextThreshold = xpThresholdForLevel(level + 1);
    final remaining = (nextThreshold - xp).clamp(0, nextThreshold);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow(opacity: 0.28, blur: 26),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Vòng trang trí mờ — tạo chiều sâu cho khối gradient thay
            // vì để phẳng hoàn toàn.
            Positioned(
              right: -34,
              top: -34,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 22,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 62,
                        height: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Vòng tiến độ chạy quanh số Level.
                            SizedBox(
                              width: 62,
                              height: 62,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 4,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.25),
                                    valueColor: const AlwaysStoppedAnimation(
                                        Colors.white),
                                  );
                                },
                              ),
                            ),
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CẤP ĐỘ $level',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$xp XP',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              remaining > 0
                                  ? 'Còn $remaining XP đến cấp ${level + 1}'
                                  : 'Sẵn sàng lên cấp!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 9,
                          backgroundColor: Colors.white.withOpacity(0.24),
                          valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).round()}% hoàn thành',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Mốc kế: $nextThreshold XP',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
