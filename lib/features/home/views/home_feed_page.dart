import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/models/user_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../gamification/utils/level_utils.dart';
import '../../observation/viewmodels/observation_feed_viewmodel.dart';
import '../../observation/widgets/observation_card.dart';
import '../../trip_planner/views/trip_planner_page.dart';

/// Feed các Observation mới nhất.
///
/// Bản nâng cấp lần 2: đầu feed có thêm (1) thanh tiến độ XP bấm được
/// dẫn tới Thành tích và (2) hàng lối tắt 4 tính năng (Nhiệm vụ, Thành
/// tích, Lộ trình, Gợi ý) — trước đây các tính năng này bị giấu sâu
/// trong bottom sheet tài khoản. Toàn bộ điều hướng/logic cũ giữ nguyên.
class HomeFeedPage extends ConsumerWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(observationFeedProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.appName,
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            const SizedBox(height: 1),
            Text(
              currentUser != null
                  ? 'Chào @${currentUser.username} 👋'
                  : 'Dấu vết đô thị quanh bạn',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _showAccountSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceOf(brightness),
                  child: currentUser?.avatarUrl != null
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              NetworkImage(currentUser!.avatarUrl!),
                        )
                      : Text(
                          (currentUser?.username.isNotEmpty ?? false)
                              ? currentUser!.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryTextOf(brightness),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.softShadow(opacity: 0.35, blur: 20),
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create-observation'),
          icon: const Icon(Icons.add_a_photo_rounded),
          label: const Text('Ghi nhận'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(observationFeedProvider);
          await ref.read(observationFeedProvider.future);
        },
        child: feedAsync.when(
          data: (observations) {
            if (observations.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.explore_outlined,
                title: 'Chưa có dấu vết đô thị nào được ghi nhận',
                subtitle:
                    'Hãy là người đầu tiên khám phá và ghi lại một điều thú vị quanh bạn.',
                action: ElevatedButton.icon(
                  onPressed: () => context.push('/create-observation'),
                  icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                  label: const Text('Ghi nhận Observation đầu tiên'),
                ),
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              itemCount: observations.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _FeedHeader(user: currentUser);
                }
                final observation = observations[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ObservationCard(
                    observation: observation,
                    onTap: () => context.push('/observation/${observation.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const LoadingStateWidget(),
          error: (error, _) => ErrorStateWidget(
            message: '$error',
            onRetry: () => ref.invalidate(observationFeedProvider),
          ),
        ),
      ),
    );
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider).valueOrNull;
    final brightness = Theme.of(context).brightness;

    showModalBottomSheet<void>(
      context: context,
      // Cần để nội dung dài không bị giới hạn ~nửa màn hình (tránh overflow).
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderOf(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.surfaceOf(brightness),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryTextOf(brightness),
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '@${user.username}',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(user.email, style: Theme.of(ctx).textTheme.labelMedium),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 15, color: AppColors.primaryTextOf(brightness)),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${user.level} · ${user.xp} XP',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTextOf(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                _SheetSectionLabel(text: 'Của tôi'),
                _SheetTile(
                  icon: Icons.person_rounded,
                  label: 'Trang cá nhân',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/profile/${user.id}');
                  },
                ),
                _SheetTile(
                  icon: Icons.bookmark_rounded,
                  label: 'Bộ sưu tập',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/bookmarks');
                  },
                ),
                _SheetSectionLabel(text: 'Tiến trình & khám phá'),
                _SheetTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'Xem thành tích',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/achievements');
                  },
                ),
                _SheetTile(
                  icon: Icons.flag_rounded,
                  label: 'Nhiệm vụ',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/missions');
                  },
                ),
                _SheetTile(
                  icon: Icons.route_rounded,
                  label: 'Lên kế hoạch khám phá',
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const TripPlannerPage()),
                    );
                  },
                ),
                _SheetTile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Gợi ý cho bạn',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/recommendations');
                  },
                ),
                if (user.isAdmin) ...[
                  _SheetSectionLabel(text: 'Quản trị viên'),
                  _SheetTile(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Quản trị',
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/admin');
                    },
                  ),
                ],
                const SizedBox(height: 6),
                const Divider(height: 1),
              ],
              _SheetTile(
                icon: Icons.logout_rounded,
                label: 'Đăng xuất',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(authViewModelProvider.notifier).logout();
                },
              ),
              // Đệm dưới cùng cho máy có gesture bar.
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phần đầu feed: thanh XP + lối tắt tính năng + tiêu đề mục.
class _FeedHeader extends StatelessWidget {
  final UserModel? user;

  const _FeedHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user != null) ...[
          _XpStrip(user: user!),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.flag_rounded,
                label: 'Nhiệm vụ',
                color: AppColors.primary,
                onTap: () => context.push('/missions'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.emoji_events_rounded,
                label: 'Thành tích',
                color: AppColors.accent,
                onTap: () => context.push('/achievements'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.route_rounded,
                label: 'Lộ trình',
                color: AppColors.rarityRare,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TripPlannerPage()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.auto_awesome_rounded,
                label: 'Gợi ý',
                color: const Color(0xFF8E5BD6),
                onTap: () => context.push('/recommendations'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: 'Mới được ghi nhận',
          subtitle: 'Những dấu vết đô thị cộng đồng vừa tìm thấy',
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _XpStrip extends StatelessWidget {
  final UserModel user;

  const _XpStrip({required this.user});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final progress = levelProgress(user.xp, user.level);
    final next = xpThresholdForLevel(user.level + 1);

    return Material(
      color: AppColors.surfaceOf(brightness),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/achievements'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(brightness)),
            boxShadow: AppColors.cardShadow(
              isDark: brightness == Brightness.dark,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: AppColors.softShadow(
                    opacity: 0.3,
                    blur: 12,
                    offset: const Offset(0, 5),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${user.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cấp ${user.level}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '${user.xp} / $next XP',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: AppColors.primary.withOpacity(0.14),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondaryOf(brightness),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Material(
      color: AppColors.surfaceOf(brightness),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderOf(brightness)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhóm nhỏ phân tách các mục trong bottom sheet tài khoản.
class _SheetSectionLabel extends StatelessWidget {
  final String text;

  const _SheetSectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
        ),
      ),
    );
  }
}

/// Mục trong bottom sheet tài khoản — icon nằm trong khối bo tròn nền nhạt.
class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: tint.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: tint),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          color: color,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: Theme.of(context).textTheme.labelMedium?.color,
      ),
    );
  }
}
