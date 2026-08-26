import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../observation/models/observation_model.dart';
import '../../observation/repositories/observation_repository.dart';
import '../../observation/widgets/observation_card.dart';
import '../models/expedition_model.dart';
import '../viewmodels/expedition_viewmodel.dart';
import '../widgets/expedition_route_preview.dart';
import '../widgets/expedition_stats_bar.dart';

/// Danh sách Observation ghi nhận được trong 1 Expedition — đặt ở đây
/// (thay vì trong expedition_viewmodel.dart) để tránh việc feature
/// expedition phải import ngược lại observation_repository chỉ vì 1
/// provider phụ; đặt cạnh nơi duy nhất dùng nó cho gọn.
final _expeditionObservationsProvider = FutureProvider.family
    .autoDispose<List<ObservationModel>, String>((ref, expeditionId) {
  final repository = ref.watch(observationRepositoryProvider);
  return repository.getObservationsForExpedition(expeditionId);
});

class ExpeditionSummaryPage extends ConsumerWidget {
  final String expeditionId;

  const ExpeditionSummaryPage({super.key, required this.expeditionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expeditionAsync = ref.watch(expeditionDetailProvider(expeditionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng kết chuyến đi'),
        automaticallyImplyLeading: false,
      ),
      body: expeditionAsync.when(
        data: (expedition) {
          if (expedition == null) {
            return const Center(child: Text('Không tìm thấy chuyến thám hiểm.'));
          }
          return _SummaryContent(expedition: expedition, expeditionId: expeditionId);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }
}

class _SummaryContent extends ConsumerWidget {
  final ExpeditionModel expedition;
  final String expeditionId;

  const _SummaryContent({required this.expedition, required this.expeditionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observationsAsync =
        ref.watch(_expeditionObservationsProvider(expeditionId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Icon(Icons.emoji_events_outlined,
              size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Hoàn thành chuyến thám hiểm!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        ExpeditionRoutePreview(routePoints: expedition.routePoints, height: 240),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ExpeditionStatsBar(
            duration: expedition.duration,
            distanceMeters: expedition.distanceMeters,
            observationCount: expedition.observationCount,
          ),
        ),
        const SizedBox(height: 28),
        Text('Những gì bạn tìm thấy',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        observationsAsync.when(
          data: (observations) {
            if (observations.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Bạn chưa ghi nhận Observation nào trong chuyến này.',
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
                          onTap: () => context.push('/observation/${o.id}'),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Lỗi tải danh sách: $e'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Xong'),
          ),
        ),
      ],
    );
  }
}
