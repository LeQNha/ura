import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/achievement_model.dart';
import '../models/gamification_result.dart';

/// Hiện lần lượt các popup ăn mừng (Lên cấp trước, rồi từng Achievement
/// mới mở khóa) dựa trên [result] — gọi hàm này ngay sau khi 1 hành
/// động thành công (tạo Observation / kết thúc Expedition) mà không
/// cần Page gọi phải tự biết thứ tự hiện popup thế nào.
Future<void> showGamificationCelebrations(
  BuildContext context,
  GamificationResult result,
) async {
  if (result.leveledUp) {
    await _showLevelUpDialog(context, result.level);
  }
  for (final achievement in result.newlyUnlocked) {
    if (!context.mounted) return;
    await _showAchievementUnlockedDialog(context, achievement);
  }
}

Future<void> _showLevelUpDialog(BuildContext context, int newLevel) async {
  if (!context.mounted) return;
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$newLevel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lên cấp!',
              style: Theme.of(ctx)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Bạn đã đạt Level $newLevel',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tuyệt vời!'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showAchievementUnlockedDialog(
  BuildContext context,
  AchievementModel achievement,
) async {
  if (!context.mounted) return;
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏅', style: TextStyle(fontSize: 20)),
            Text(
              'ACHIEVEMENT MỞ KHÓA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(achievement.icon, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${achievement.xpReward} XP',
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tuyệt vời!'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
