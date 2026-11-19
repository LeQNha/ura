import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_firestore_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../community/providers/community_providers.dart';
import '../../community/repositories/community_repository.dart';
import '../../observation/models/observation_model.dart';
import '../../observation/repositories/observation_repository.dart';
import '../../observation/widgets/observation_card.dart';

/// Hồ sơ người dùng.
///
/// Bản nâng cấp: banner gradient + avatar lớn viền trắng đè lên mép
/// banner, huy hiệu Level/XP, 3 số liệu trong 1 thẻ có vạch ngăn, nút
/// theo dõi dạng gradient. Logic/provider giữ nguyên.
class ProfilePage extends ConsumerWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwnProfile = currentUser?.id == userId;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyStateWidget(
              icon: Icons.person_off_outlined,
              title: 'Không tìm thấy người dùng',
              subtitle: 'Tài khoản này có thể đã bị xóa hoặc không tồn tại.',
            ),
          );
        }
        return _ProfileView(
          profile: profile,
          userId: userId,
          isOwnProfile: isOwnProfile,
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const LoadingStateWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateWidget(
          message: '$e',
          onRetry: () => ref.invalidate(userProfileProvider(userId)),
        ),
      ),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  final UserModel profile;
  final String userId;
  final bool isOwnProfile;

  const _ProfileView({
    required this.profile,
    required this.userId,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final observationsAsync = ref.watch(_profileObservationsProvider(userId));
    final topInset = MediaQuery.of(context).padding.top;
    const bannerHeight = 150.0;
    const avatarRadius = 48.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text(''),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Banner gradient + vòng trang trí.
          SizedBox(
            height: bannerHeight + topInset,
            child: Container(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Stack(
                children: [
                  Positioned(
                    top: -50,
                    right: -30,
                    child: _ring(190, 20),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -30,
                    child: _ring(130, 16),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -avatarRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                      boxShadow: AppColors.neutralShadow(
                        opacity: 0.16,
                        blur: 18,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? Text(
                              profile.username.isNotEmpty
                                  ? profile.username[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryTextOf(brightness),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName
                        : profile.username,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text('@${profile.username}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.softShadow(
                        opacity: 0.25,
                        blur: 12,
                        offset: const Offset(0, 5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Level ${profile.level} · ${profile.xp} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.bio != null &&
                      profile.bio!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _StatsCard(profile: profile),
                  if (!isOwnProfile) ...[
                    const SizedBox(height: 16),
                    _FollowButton(targetUserId: userId),
                  ],
                  const SizedBox(height: 26),
                  SectionHeader(
                    title: 'Nhật ký khám phá',
                    trailing: observationsAsync.valueOrNull == null
                        ? null
                        : Text(
                            '${observationsAsync.valueOrNull!.length} ghi nhận',
                            style: theme.textTheme.labelMedium,
                          ),
                  ),
                  const SizedBox(height: 14),
                  observationsAsync.when(
                    data: (observations) {
                      if (observations.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_camera_back_outlined,
                                size: 36,
                                color: AppColors.textSecondaryOf(brightness),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Chưa có Observation nào.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: observations
                            .map((o) => Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: ObservationCard(
                                    observation: o,
                                    onTap: () =>
                                        context.push('/observation/${o.id}'),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Lỗi: $e'),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _ring(double size, double width) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.14), width: width),
      ),
    );
  }
}

final _profileObservationsProvider = StreamProvider.family
    .autoDispose<List<ObservationModel>, String>((ref, userId) {
  final repository = ref.watch(observationRepositoryProvider);
  return repository.watchObservationsByCreator(userId);
});

class _StatsCard extends StatelessWidget {
  final UserModel profile;

  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    Widget divider() => Container(
          width: 1,
          height: 30,
          color: AppColors.borderOf(brightness),
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(brightness),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderOf(brightness)),
        boxShadow: AppColors.cardShadow(isDark: brightness == Brightness.dark),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
                value: '${profile.observationCount}', label: 'Ghi nhận'),
          ),
          divider(),
          Expanded(
            child: _StatColumn(
                value: '${profile.followerCount}', label: 'Follower'),
          ),
          divider(),
          Expanded(
            child: _StatColumn(
                value: '${profile.followingCount}', label: 'Following'),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTextOf(theme.brightness),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelMedium),
      ],
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  final String targetUserId;

  const _FollowButton({required this.targetUserId});

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(communityRepositoryProvider)
          .toggleFollow(currentUser.id, widget.targetUserId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFollowingAsync =
        ref.watch(isFollowingProvider(widget.targetUserId));
    final isFollowing = isFollowingAsync.valueOrNull ?? false;

    return SizedBox(
      width: double.infinity,
      child: isFollowing
          ? OutlinedButton.icon(
              onPressed: _loading ? null : _toggle,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Đang theo dõi'),
            )
          : GradientButton(
              label: 'Theo dõi',
              icon: Icons.person_add_alt_1_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _toggle,
            ),
    );
  }
}
