import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../observation/viewmodels/observation_feed_viewmodel.dart';
import '../../observation/widgets/observation_card.dart';
import '../../trip_planner/views/trip_planner_page.dart';

/// Feed các Observation mới nhất.
///
/// Bản nâng cấp giao diện: AppBar chuyển thành header 2 dòng (tên app
/// + lời chào theo tên user) với avatar có viền gradient, mục tài
/// khoản trong bottom sheet được nhóm lại có tiêu đề nhóm + header hồ
/// sơ nổi bật, empty state dùng chung EmptyStateWidget đã nâng cấp.
/// TOÀN BỘ hành vi/điều hướng giữ nguyên — chỉ đổi cách trình bày.
class HomeFeedPage extends ConsumerWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(observationFeedProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

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
                  ? 'Chào @${currentUser.username} · Level ${currentUser.level}'
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
                  backgroundColor: AppColors.surfaceLight,
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
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-observation'),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Ghi nhận'),
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
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: observations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final observation = observations[index];
                return ObservationCard(
                  observation: observation,
                  onTap: () => context.push('/observation/${observation.id}'),
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
    showModalBottomSheet<void>(
      context: context,
      // Bắt buộc thêm — không có dòng này, bottom sheet bị giới hạn
      // chiều cao mặc định (khoảng nửa màn hình) và KHÔNG cho phép nội
      // dung bên trong vượt quá đó dù có bọc ScrollView, dẫn đến lỗi
      // tràn layout (overflow) khi danh sách mục dài hơn khung hình.
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
                  color: const Color(0xFFDAD7D0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              if (user != null) ...[
                // Header hồ sơ — avatar lớn viền gradient + tên + chip
                // Level/XP, thay cho 3 dòng chữ rời rạc trước đây.
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
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
                      const Icon(Icons.bolt_rounded,
                          size: 15, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${user.level} · ${user.xp} XP',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
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
              // Đệm thêm dưới cùng — trên vài dòng máy có gesture bar
              // (thanh cử chỉ), nếu không có đệm này nút "Đăng xuất"
              // dễ bị dính sát/khuất sau gesture bar.
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhóm nhỏ phân tách các mục trong bottom sheet tài khoản —
/// giúp danh sách dài dễ quét mắt hơn thay vì 1 dãy ListTile liền mạch.
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

/// Mục trong bottom sheet tài khoản — icon nằm trong khối bo tròn nền
/// nhạt (thay icon trần), tạo nhịp thị giác đều đặn giữa các dòng.
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
