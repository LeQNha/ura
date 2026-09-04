import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../gamification/widgets/gamification_dialogs.dart';
import '../models/mission_model.dart';
import '../repositories/mission_repository.dart';
import '../services/mission_service.dart';

class MissionsPage extends ConsumerWidget {
  const MissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(missionsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhiệm vụ')),
      body: currentUser == null
          ? const LoadingStateWidget()
          : missionsAsync.when(
              data: (missions) {
                if (missions.isEmpty) {
                  return const _EmptyMissionsCard();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: missions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _MissionCard(
                    mission: missions[index],
                    user: currentUser,
                  ),
                );
              },
              loading: () => const LoadingStateWidget(),
              error: (e, _) => ErrorStateWidget(
                message: '$e',
                onRetry: () => ref.invalidate(missionsStreamProvider),
              ),
            ),
    );
  }
}

class _MissionCard extends ConsumerStatefulWidget {
  final MissionModel mission;
  final UserModel user;

  const _MissionCard({required this.mission, required this.user});

  @override
  ConsumerState<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends ConsumerState<_MissionCard> {
  double? _progress;
  bool _loadingProgress = true;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final repo = ref.read(missionRepositoryProvider);
    final value = await repo.getProgress(widget.user, widget.mission);
    if (mounted) setState(() {
      _progress = value;
      _loadingProgress = false;
    });
  }

  Future<void> _claim() async {
    setState(() => _claiming = true);
    try {
      final result = await ref
          .read(missionRepositoryProvider)
          .claimMission(widget.user, widget.mission);
      if (!mounted) return;
      if (result != null) {
        await showGamificationCelebrations(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final completedIdsAsync = ref.watch(_completedIdsProvider(widget.user.id));
    final completedIds = completedIdsAsync.valueOrNull ?? [];
    final isCompleted = completedIds.contains(mission.id);

    final progress = _progress ?? 0;
    final ratio = (progress / mission.targetValue).clamp(0.0, 1.0);
    final canClaim = !isCompleted && progress >= mission.targetValue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success.withOpacity(0.06)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withOpacity(0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(mission.icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mission.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(mission.description,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: AppColors.success, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingProgress)
            const LinearProgressIndicator(minHeight: 6)
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(
                  isCompleted ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mission.type == MissionType.distance
                    ? '${_formatDistanceShort(progress)} / ${mission.unitLabel}'
                    : '${progress.toInt()} / ${mission.unitLabel}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text('+${mission.rewardXp} XP',
                  style: const TextStyle(
                      color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          if (canClaim) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _claiming ? null : _claim,
                child: _claiming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Nhận thưởng'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDistanceShort(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

final _completedIdsProvider =
    StreamProvider.family.autoDispose<List<String>, String>((ref, userId) {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.watchCompletedMissionIds(userId);
});

class _EmptyMissionsCard extends ConsumerStatefulWidget {
  const _EmptyMissionsCard();

  @override
  ConsumerState<_EmptyMissionsCard> createState() => _EmptyMissionsCardState();
}

class _EmptyMissionsCardState extends ConsumerState<_EmptyMissionsCard> {
  bool _seeding = false;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.flag_outlined,
      title: 'Chưa có Nhiệm vụ nào trong hệ thống.',
      subtitle:
          'Thao tác chỉ cần làm 1 lần cho cả app (tạm thời thay cho Admin Dashboard).',
      action: ElevatedButton(
        onPressed: _seeding
            ? null
            : () async {
                setState(() => _seeding = true);
                await ref.read(missionServiceProvider).seedDefaultMissions();
                if (mounted) setState(() => _seeding = false);
              },
        child: _seeding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Khởi tạo Nhiệm vụ mặc định'),
      ),
    );
  }
}
