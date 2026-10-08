import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/achievement_model.dart';
import '../models/gamification_result.dart';

/// Hiện lần lượt các popup ăn mừng (Lên cấp trước, rồi từng Achievement
/// mới mở khóa) dựa trên [result] — gọi hàm này ngay sau khi 1 hành
/// động thành công (tạo Observation / nhận thưởng Mission) mà không
/// cần Page gọi phải tự biết thứ tự hiện popup thế nào.
///
/// Bản nâng cấp giao diện: popup có hiệu ứng phóng to đàn hồi khi xuất
/// hiện, huy hiệu dạng nhiều vòng đồng tâm phát sáng, tia sáng toả
/// phía sau — đây là "khoảnh khắc thưởng" của app nên được phép cầu kỳ
/// hơn hẳn các màn thường (nguyên tắc: dồn sự nổi bật vào đúng vài chỗ).
/// KHÔNG đổi chữ ký hàm `showGamificationCelebrations(context, result)`.
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

/// Bọc nội dung popup trong hiệu ứng phóng to đàn hồi (elastic) —
/// dùng chung cho cả 2 loại popup để nhịp xuất hiện nhất quán.
class _PopScaleIn extends StatefulWidget {
  final Widget child;

  const _PopScaleIn({required this.child});

  @override
  State<_PopScaleIn> createState() => _PopScaleInState();
}

class _PopScaleInState extends State<_PopScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Huy hiệu tròn nhiều lớp + tia sáng phía sau — phần "ăn tiền" về mặt
/// thị giác của cả 2 popup.
class _GlowMedallion extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final Color glowColor;

  const _GlowMedallion({
    required this.child,
    required this.gradient,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tia sáng toả — vẽ bằng 12 thanh mảnh xoay quanh tâm.
          for (var i = 0; i < 12; i++)
            Transform.rotate(
              angle: i * 3.14159 / 6,
              child: Container(
                width: 3,
                height: 146,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [glowColor.withOpacity(0.28), Colors.transparent],
                  ),
                ),
              ),
            ),
          // Vòng ngoài mờ
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor.withOpacity(0.10),
            ),
          ),
          // Vòng giữa
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glowColor.withOpacity(0.16),
            ),
          ),
          // Lõi gradient
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.45),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ],
      ),
    );
  }
}

Future<void> _showLevelUpDialog(BuildContext context, int newLevel) async {
  if (!context.mounted) return;
  return showDialog<void>(
    context: context,
    builder: (ctx) => _PopScaleIn(
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'THĂNG CẤP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark.withOpacity(0.8),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              _GlowMedallion(
                gradient: AppColors.primaryGradient,
                glowColor: AppColors.primary,
                child: Text(
                  '$newLevel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lên cấp!',
                style: Theme.of(ctx)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Bạn đã đạt Level $newLevel — tiếp tục khám phá nhé.',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 22),
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
    builder: (ctx) => _PopScaleIn(
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ACHIEVEMENT MỞ KHÓA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent.withOpacity(0.9),
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              _GlowMedallion(
                gradient: AppColors.heroGradient,
                glowColor: AppColors.accent,
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 40),
                ),
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
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.success.withOpacity(0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded,
                        size: 15, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      '+${achievement.xpReward} XP',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
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
    ),
  );
}
