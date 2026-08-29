import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/user_firestore_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../community/models/report_model.dart';
import '../../community/providers/community_providers.dart';
import '../../community/repositories/community_repository.dart';
import '../../gamification/models/achievement_model.dart';
import '../../gamification/services/achievement_service.dart';
import '../../observation/models/category_model.dart';
import '../../observation/repositories/observation_repository.dart';
import '../../observation/services/category_service.dart';

/// Admin Dashboard — 4 khu vực quản trị cơ bản: Báo cáo (moderation),
/// Danh mục, Achievement, Người dùng. Chỉ user có `role == 'admin'`
/// mới vào được — kiểm tra ngay trong widget này (không sửa Route
/// Guard toàn cục ở app_router.dart để tránh rủi ro ảnh hưởng luồng
/// Auth đã ổn định từ Phase 0).
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản trị')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Bạn không có quyền truy cập trang này.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.flag_outlined), text: 'Báo cáo'),
              Tab(icon: Icon(Icons.category_outlined), text: 'Danh mục'),
              Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Achievement'),
              Tab(icon: Icon(Icons.people_outline), text: 'Người dùng'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReportsTab(),
            _CategoriesTab(),
            _AchievementsTab(),
            _UsersTab(),
          ],
        ),
      ),
    );
  }
}

// =======================================================================
// Tab 1 — Báo cáo
// =======================================================================

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  Future<void> _resolve(WidgetRef ref, String reportId) async {
    await ref.read(communityRepositoryProvider).resolveReport(reportId);
  }

  Future<void> _deleteObservation(
    BuildContext context,
    WidgetRef ref,
    ReportModel report,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa Observation bị báo cáo?'),
        content: Text('"${report.observationTitle}" sẽ không còn hiển thị công khai.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(observationRepositoryProvider)
        .softDeleteObservation(report.observationId);
    await _resolve(ref, report.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(allReportsProvider);

    return reportsAsync.when(
      data: (reports) {
        final pending =
            reports.where((r) => r.status == ReportStatus.pending).toList();
        final resolved =
            reports.where((r) => r.status == ReportStatus.resolved).toList();

        if (reports.isEmpty) {
          return const Center(child: Text('Chưa có báo cáo nào.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              Text('Đang chờ xử lý (${pending.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...pending.map((r) => _ReportCard(
                    report: r,
                    onDismiss: () => _resolve(ref, r.id),
                    onDelete: () => _deleteObservation(context, ref, r),
                  )),
            ],
            if (resolved.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Đã xử lý (${resolved.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...resolved.map((r) => _ReportCard(report: r)),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  const _ReportCard({required this.report, this.onDismiss, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPending = report.status == ReportStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending
            ? AppColors.warning.withOpacity(0.08)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report.observationTitle,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Lý do: ${report.reason}', style: const TextStyle(fontSize: 13)),
          Text('Báo cáo bởi @${report.reporterUsername}',
              style: Theme.of(context).textTheme.labelMedium),
          if (isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(onPressed: onDismiss, child: const Text('Bỏ qua')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Xóa Observation',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =======================================================================
// Tab 2 — Danh mục
// =======================================================================

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final iconController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm danh mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Icon (emoji)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm')),
        ],
      ),
    );

    if (confirmed == true &&
        nameController.text.trim().isNotEmpty &&
        iconController.text.trim().isNotEmpty) {
      await ref.read(categoryServiceProvider).createCategory(
            name: nameController.text.trim(),
            icon: iconController.text.trim(),
            order: 999,
          );
    }
  }

  Future<void> _delete(WidgetRef ref, String id) async {
    await ref.read(categoryServiceProvider).deleteCategory(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final CategoryModel c = categories[index];
              return ListTile(
                leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
                title: Text(c.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _delete(ref, c.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

// =======================================================================
// Tab 3 — Achievement
// =======================================================================

class _AchievementsTab extends ConsumerWidget {
  const _AchievementsTab();

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final iconController = TextEditingController();
    final xpController = TextEditingController(text: '20');
    final valueController = TextEditingController(text: '1');
    String conditionType = AchievementConditionType.observationCount;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Thêm Achievement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: iconController,
                  decoration: const InputDecoration(labelText: 'Icon (emoji)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: xpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'XP thưởng'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: conditionType,
                  decoration: const InputDecoration(labelText: 'Loại điều kiện'),
                  items: const [
                    DropdownMenuItem(
                        value: AchievementConditionType.observationCount,
                        child: Text('Số Observation')),
                    DropdownMenuItem(
                        value: AchievementConditionType.expeditionCount,
                        child: Text('Số Expedition')),
                    DropdownMenuItem(
                        value: AchievementConditionType.rarityFound,
                        child: Text('Rarity tìm được (0-3)')),
                    DropdownMenuItem(
                        value: AchievementConditionType.totalDistance,
                        child: Text('Tổng quãng đường (m)')),
                  ],
                  onChanged: (v) => setState(() => conditionType = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ngưỡng điều kiện'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm')),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        nameController.text.trim().isNotEmpty &&
        iconController.text.trim().isNotEmpty) {
      await ref.read(achievementServiceProvider).createAchievement(
            name: nameController.text.trim(),
            description: descController.text.trim(),
            icon: iconController.text.trim(),
            xpReward: int.tryParse(xpController.text) ?? 20,
            conditionType: conditionType,
            conditionValue: num.tryParse(valueController.text) ?? 1,
          );
    }
  }

  Future<void> _delete(WidgetRef ref, String id) async {
    await ref.read(achievementServiceProvider).deleteAchievement(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsStreamProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return const Center(child: Text('Chưa có Achievement nào.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final AchievementModel a = achievements[index];
              return ListTile(
                leading: Text(a.icon, style: const TextStyle(fontSize: 22)),
                title: Text(a.name),
                subtitle: Text('${a.description} · +${a.xpReward} XP'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _delete(ref, a.id),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

// =======================================================================
// Tab 4 — Người dùng
// =======================================================================

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  Future<void> _toggleRole(BuildContext context, WidgetRef ref, UserModel user) async {
    final newRole = user.isAdmin ? 'user' : 'admin';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(user.isAdmin ? 'Thu hồi quyền Admin?' : 'Cấp quyền Admin?'),
        content: Text('@${user.username} sẽ trở thành "$newRole".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(userFirestoreServiceProvider).updateUserRole(user.id, newRole);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      data: (users) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.primaryDark, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text('@${user.username}'),
              subtitle: Text(user.email),
              trailing: FilterChip(
                label: Text(user.isAdmin ? 'Admin' : 'User'),
                selected: user.isAdmin,
                selectedColor: AppColors.primary.withOpacity(0.2),
                onSelected: (_) => _toggleRole(context, ref, user),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }
}
