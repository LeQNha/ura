import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../gamification/widgets/gamification_dialogs.dart';
import '../models/expedition_model.dart';
import '../viewmodels/expedition_viewmodel.dart';
import '../widgets/expedition_route_preview.dart';
import '../widgets/expedition_stats_bar.dart';

class ExpeditionPage extends ConsumerStatefulWidget {
  const ExpeditionPage({super.key});

  @override
  ConsumerState<ExpeditionPage> createState() => _ExpeditionPageState();
}

class _ExpeditionPageState extends ConsumerState<ExpeditionPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Đồng hồ đếm giờ hiển thị — chỉ để rebuild UI mỗi giây, không liên
    // quan đến logic GPS (logic đó nằm trong ViewModel, chạy độc lập).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeExpeditionProvider);
    final actionState = ref.watch(expeditionViewModelProvider);
    final viewModel = ref.read(expeditionViewModelProvider.notifier);

    // Nếu phát hiện có Expedition active trên Firestore nhưng ViewModel
    // (bộ nhớ) chưa biết về nó — trường hợp app vừa mở lại giữa chừng
    // 1 chuyến đi — tự động resume GPS stream.
    ref.listen<AsyncValue<ExpeditionModel?>>(activeExpeditionProvider,
        (previous, next) {
      next.whenData((expedition) {
        if (expedition != null) viewModel.resume(expedition);
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Thám hiểm')),
      body: activeAsync.when(
        data: (expedition) {
          if (expedition == null) {
            return _StartView(actionState: actionState, viewModel: viewModel);
          }
          return _ActiveView(
            expedition: expedition,
            now: _now,
            actionState: actionState,
            viewModel: viewModel,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

class _StartView extends StatelessWidget {
  final ExpeditionActionState actionState;
  final ExpeditionViewModel viewModel;

  const _StartView({required this.actionState, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.hiking, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Bắt đầu một chuyến thám hiểm',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Ứng dụng sẽ ghi lại quãng đường bạn đi và mọi Observation '
              'bạn tạo trong lúc thám hiểm, gộp lại thành 1 hành trình.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: actionState.isStarting ? null : viewModel.start,
                icon: actionState.isStarting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Bắt đầu thám hiểm'),
              ),
            ),
            if (actionState.error != null) ...[
              const SizedBox(height: 12),
              Text(
                actionState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveView extends ConsumerWidget {
  final ExpeditionModel expedition;
  final DateTime now;
  final ExpeditionActionState actionState;
  final ExpeditionViewModel viewModel;

  const _ActiveView({
    required this.expedition,
    required this.now,
    required this.actionState,
    required this.viewModel,
  });

  Future<void> _handleEnd(BuildContext context, WidgetRef ref) async {
    final id = await viewModel.end();
    if (id == null || !context.mounted) return;

    // Đọc lại state MỚI NHẤT qua ref (không dùng `actionState` — field
    // đó là giá trị tại thời điểm widget này được build, TRƯỚC khi
    // end() chạy xong, nên sẽ là dữ liệu cũ/null nếu đọc trực tiếp).
    final result = ref.read(expeditionViewModelProvider).gamificationResult;
    if (result != null) {
      await showGamificationCelebrations(context, result);
    }
    if (!context.mounted) return;

    context.push('/expedition/$id/summary');
  }

  Future<void> _handleCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy chuyến thám hiểm?'),
        content: const Text(
          'Quãng đường đã ghi sẽ không được lưu lại. Các Observation đã '
          'tạo trong lúc này vẫn được giữ nguyên.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục thám hiểm')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy chuyến',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await viewModel.cancel();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = now.difference(expedition.startedAt);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.error.withOpacity(0.08),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Đang thám hiểm',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ExpeditionRoutePreview(routePoints: expedition.routePoints),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ExpeditionStatsBar(
            duration: elapsed,
            distanceMeters: expedition.distanceMeters,
            observationCount: expedition.observationCount,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/create-observation'),
          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
          label: const Text('Ghi nhận ngay'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                actionState.isEnding ? null : () => _handleEnd(context, ref),
            icon: actionState.isEnding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.flag_outlined),
            label: const Text('Kết thúc thám hiểm'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: actionState.isEnding ? null : () => _handleCancel(context),
          child: const Text('Hủy chuyến',
              style: TextStyle(color: AppColors.error)),
        ),
        if (actionState.error != null) ...[
          const SizedBox(height: 8),
          Text(
            actionState.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
