import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/achievement_model.dart';
import '../services/achievement_service.dart';
import '../widgets/level_progress_card.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final achievementsAsync = ref.watch(achievementsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thành tích')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Không tìm thấy người dùng.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              LevelProgressCard(xp: user.xp, level: user.level),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Achievement',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '${user.unlockedAchievementIds.length} đã mở khóa',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              achievementsAsync.when(
                data: (achievements) {
                  if (achievements.isEmpty) {
                    return _EmptyAchievementsCard();
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      final unlocked =
                          user.unlockedAchievementIds.contains(achievement.id);
                      return _AchievementTile(
                        achievement: achievement,
                        unlocked: unlocked,
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Lỗi tải achievement: $e'),
              ),
            ],
          );
        },
        loading: () => const LoadingStateWidget(),
        error: (e, _) => ErrorStateWidget(message: '$e'),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementModel achievement;
  final bool unlocked;

  const _AchievementTile({required this.achievement, required this.unlocked});

  void _showDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(child: Text(achievement.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 10),
            Text(
              unlocked
                  ? '✅ Đã mở khóa · +${achievement.xpReward} XP'
                  : '🔒 Chưa mở khóa · Thưởng ${achievement.xpReward} XP',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    unlocked ? AppColors.success : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.primary.withOpacity(0.08)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.primary.withOpacity(0.3)
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.35,
              child:
                  Text(achievement.icon, style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: unlocked ? null : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 4),
            if (!unlocked)
              const Icon(Icons.lock_outline,
                  size: 14, color: AppColors.textSecondaryLight),
          ],
        ),
      ),
    );
  }
}

class _EmptyAchievementsCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_EmptyAchievementsCard> createState() =>
      _EmptyAchievementsCardState();
}

class _EmptyAchievementsCardState
    extends ConsumerState<_EmptyAchievementsCard> {
  bool _seeding = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chưa có Achievement nào trong hệ thống.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thao tác chỉ cần làm 1 lần cho cả app (tạm thời thay cho '
            'Admin Dashboard chưa được xây).',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _seeding
                ? null
                : () async {
                    setState(() => _seeding = true);
                    await ref
                        .read(achievementServiceProvider)
                        .seedDefaultAchievements();
                    if (mounted) setState(() => _seeding = false);
                  },
            child: _seeding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Khởi tạo Achievement mặc định'),
          ),
        ],
      ),
    );
  }
}
