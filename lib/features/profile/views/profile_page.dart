import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/services/user_firestore_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../community/providers/community_providers.dart';
import '../../community/repositories/community_repository.dart';
import '../../observation/models/observation_model.dart';
import '../../observation/repositories/observation_repository.dart';
import '../../observation/widgets/observation_card.dart';

class ProfilePage extends ConsumerWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isOwnProfile = currentUser?.id == userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Không tìm thấy người dùng.'));
          }

          final observationsAsync =
              ref.watch(_profileObservationsProvider(userId));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: profile.avatarUrl != null
                      ? NetworkImage(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          profile.username.isNotEmpty
                              ? profile.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(profile.displayName,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Center(
                child: Text('@${profile.username} · Level ${profile.level}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
              if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  profile.bio!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatColumn(
                      value: '${profile.observationCount}', label: 'Ghi nhận'),
                  _StatColumn(
                      value: '${profile.followerCount}', label: 'Follower'),
                  _StatColumn(
                      value: '${profile.followingCount}', label: 'Following'),
                ],
              ),
              const SizedBox(height: 20),
              if (!isOwnProfile) _FollowButton(targetUserId: userId),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text('Observation đã ghi nhận',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              observationsAsync.when(
                data: (observations) {
                  if (observations.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Chưa có Observation nào.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return Column(
                    children: observations
                        .map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
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
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Lỗi: $e'),
              ),
            ],
          );
        },
        loading: () => const LoadingStateWidget(),
        error: (e, _) => ErrorStateWidget(
          message: '$e',
          onRetry: () => ref.invalidate(userProfileProvider(userId)),
        ),
      ),
    );
  }
}

final _profileObservationsProvider = StreamProvider.family
    .autoDispose<List<ObservationModel>, String>((ref, userId) {
  final repository = ref.watch(observationRepositoryProvider);
  return repository.watchObservationsByCreator(userId);
});

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
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
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Đang theo dõi'),
            )
          : ElevatedButton.icon(
              onPressed: _loading ? null : _toggle,
              icon: const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Theo dõi'),
            ),
    );
  }
}
