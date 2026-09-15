import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../observation/viewmodels/observation_feed_viewmodel.dart';
import '../../observation/widgets/observation_card.dart';
import '../../trip_planner/views/trip_planner_page.dart';

/// Feed các Observation mới nhất.
///
/// Đây CHƯA phải Map screen thật (Phase 2). Mục đích ở Phase 1 là có
/// một nơi để: (1) xác nhận Create Observation hoạt động đúng đầu-cuối,
/// (2) hiển thị ObservationCard trong bối cảnh thật thay vì cô lập.
/// Khi Phase 2 hoàn thành, route /home sẽ trỏ sang Map screen, còn Feed
/// này có thể giữ lại làm tab "Explore" riêng (đã có trong tài liệu UI).
class HomeFeedPage extends ConsumerWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(observationFeedProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: currentUser?.avatarUrl != null
                ? CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(currentUser!.avatarUrl!),
                  )
                : CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      (currentUser?.username.isNotEmpty ?? false)
                          ? currentUser!.username[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
            onPressed: () => _showAccountSheet(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-observation'),
        icon: const Icon(Icons.add_a_photo_outlined),
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
              return _EmptyFeed(
                onCreate: () => context.push('/create-observation'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: observations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final observation = observations[index];
                return ObservationCard(
                  observation: observation,
                  onTap: () => context.push('/observation/${observation.id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Lỗi tải dữ liệu: $error')),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              if (user != null) ...[
                Text('@${user.username}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(user.email,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Text('Level ${user.level} · ${user.xp} XP',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: AppColors.primary),
                  title: const Text('Trang cá nhân'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/profile/${user.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_outline,
                      color: AppColors.primary),
                  title: const Text('Bộ sưu tập'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/bookmarks');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined,
                      color: AppColors.primary),
                  title: const Text('Xem thành tích'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/achievements');
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.flag_outlined, color: AppColors.primary),
                  title: const Text('Nhiệm vụ'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/missions');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.route_outlined,
                      color: AppColors.primary),
                  title: const Text('Lên kế hoạch khám phá'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const TripPlannerPage()),
                    );
                  },
                ),
                if (user.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined,
                        color: AppColors.primary),
                    title: const Text('Quản trị'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/admin');
                    },
                  ),
              ],
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Đăng xuất',
                    style: TextStyle(color: AppColors.error)),
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

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyFeed({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_outlined,
                size: 56, color: AppColors.textSecondaryLight),
            const SizedBox(height: 16),
            Text(
              'Chưa có dấu vết đô thị nào được ghi nhận',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy là người đầu tiên khám phá và ghi lại một điều thú vị quanh bạn.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Ghi nhận Observation đầu tiên'),
            ),
          ],
        ),
      ),
    );
  }
}
