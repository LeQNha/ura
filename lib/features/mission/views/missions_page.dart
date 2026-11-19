import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../gamification/widgets/gamification_dialogs.dart';
import '../models/mission_model.dart';
import '../repositories/mission_repository.dart';
import '../services/mission_service.dart';

/// Danh sách Nhiệm vụ.
///
/// Bản nâng cấp: banner tổng quan (đã hoàn thành / tổng + XP có thể nhận),
/// thẻ nhiệm vụ có icon trong khối bo tròn, trạng thái (Đang làm / Sẵn
/// sàng nhận / Hoàn thành), thanh tiến độ gradient có animation. Logic
/// tải tiến độ + nhận thưởng giữ nguyên.
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
                final completedIds = ref
                        .watch(_completedIdsProvider(currentUser.id))
                        .valueOrNull ??
                    <String>[];
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  itemCount: missions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SummaryBanner(
                          missions: missions,
                          completedIds: completedIds,
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MissionCard(
                        mission: missions[index - 1],
                        user: currentUser,
                      ),
                    );
                  },
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

class _SummaryBanner extends StatelessWidget {
  final List<MissionModel> missions;
  final List<String> completedIds;

  const _SummaryBanner({required this.missions, required this.completedIds});

  @override
  Widget build(BuildContext context) {
    final total = missions.length;
    final done = missions.where((m) => completedIds.contains(m.id)).length;
    final pendingXp = missions
        .where((m) => !completedIds.contains(m.id))
        .fold<int>(0, (sum, m) => sum + m.rewardXp);
    final ratio = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow(opacity: 0.25, blur: 24),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                Text(
                  '$done/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done == total && total > 0
                      ? 'Hoàn thành tất cả! 🎉'
                      : 'Tiến độ nhiệm vụ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingXp > 0
                      ? 'Còn $pendingXp XP đang chờ bạn chinh phục'
                      : 'Bạn đã nhận toàn bộ phần thưởng',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    if (mounted) {
      setState(() {
        _progress = value;
        _loadingProgress = false;
      });
    }
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
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final mission = widget.mission;
    final completedIdsAsync = ref.watch(_completedIdsProvider(widget.user.id));
    final completedIds = completedIdsAsync.valueOrNull ?? [];
    final isCompleted = completedIds.contains(mission.id);

    final progress = _progress ?? 0;
    final ratio = (progress / mission.targetValue).clamp(0.0, 1.0);
    final canClaim = !isCompleted && progress >= mission.targetValue;

    final Color tint = isCompleted
        ? AppColors.success
        : (canClaim ? AppColors.accent : AppColors.primary);
    final String status =
        isCompleted ? 'Hoàn thành' : (canClaim ? 'Sẵn sàng nhận' : 'Đang làm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? Color.alphaBlend(
                AppColors.success.withOpacity(0.06),
                AppColors.surfaceOf(brightness),
              )
            : AppColors.surfaceOf(brightness),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withOpacity(0.35)
              : AppColors.borderOf(brightness),
        ),
        boxShadow: AppColors.cardShadow(isDark: brightness == Brightness.dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(mission.icon, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(mission.description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCompleted) ...[
                      Icon(Icons.check_circle_rounded, size: 12, color: tint),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: tint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingProgress)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(minHeight: 8),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: tint.withOpacity(0.14),
                  valueColor: AlwaysStoppedAnimation(tint),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mission.type == MissionType.distance
                    ? '${_formatDistanceShort(progress)} / ${mission.unitLabel}'
                    : '${progress.toInt()} / ${mission.unitLabel}',
                style: theme.textTheme.labelMedium,
              ),
              Row(
                children: [
                  Icon(Icons.bolt_rounded,
                      size: 14, color: AppColors.primaryTextOf(brightness)),
                  Text(
                    '+${mission.rewardXp} XP',
                    style: TextStyle(
                      color: AppColors.primaryTextOf(brightness),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (canClaim) ...[
            const SizedBox(height: 14),
            GradientButton(
              label: 'Nhận thưởng',
              icon: Icons.card_giftcard_rounded,
              height: 48,
              isLoading: _claiming,
              onPressed: _claiming ? null : _claim,
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
      action: SizedBox(
        width: 260,
        child: GradientButton(
          label: 'Khởi tạo Nhiệm vụ mặc định',
          isLoading: _seeding,
          onPressed: _seeding
              ? null
              : () async {
                  setState(() => _seeding = true);
                  await ref.read(missionServiceProvider).seedDefaultMissions();
                  if (mounted) setState(() => _seeding = false);
                },
        ),
      ),
    );
  }
}
