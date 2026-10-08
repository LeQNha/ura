import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../observation/widgets/observation_card.dart';
import '../providers/ai_providers.dart';
import '../services/ai_service.dart';

/// Màn "Gợi ý cho bạn" — hiển thị các Observation do AI Backend chấm
/// điểm phù hợp nhất, kèm **lý do** cho từng gợi ý.
///
/// Hiển thị lý do là có chủ đích: hệ gợi ý không giải thích được sẽ
/// giống một "hộp đen" khó tin tưởng; và khi bảo vệ đồ án, đây là cách
/// trực quan nhất để chứng minh thuật toán đang hoạt động đúng ý đồ
/// chứ không phải xáo trộn ngẫu nhiên.
class RecommendationsPage extends ConsumerWidget {
  const RecommendationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);
    final serverOnline = ref.watch(aiServerStatusProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gợi ý cho bạn'),
        actions: [
          IconButton(
            tooltip: 'Làm mới gợi ý',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(recommendationsProvider);
              ref.invalidate(aiServerStatusProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (serverOnline == false) const _ServerOfflineBanner(),
          Expanded(
            child: recommendationsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Chưa có gợi ý nào',
                    subtitle: serverOnline == false
                        ? 'Cần bật AI server để tạo gợi ý. Xem hướng dẫn trong README của thư mục ai_server.'
                        : 'Hãy ghi nhận thêm vài Observation để hệ thống hiểu sở thích của bạn, '
                            'hoặc chờ cộng đồng đóng góp thêm phát hiện mới quanh đây.',
                    action: OutlinedButton.icon(
                      onPressed: () {
                        ref.invalidate(recommendationsProvider);
                        ref.invalidate(aiServerStatusProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    if (index == 0) return const _IntroCard();

                    final item = items[index - 1];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ReasonChip(
                          reason: item.recommendation.reason,
                          distanceMeters: item.recommendation.distanceMeters,
                        ),
                        const SizedBox(height: 8),
                        ObservationCard(
                          observation: item.observation,
                          onTap: () => context
                              .push('/observation/${item.observation.id}'),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const LoadingStateWidget(
                message: 'Đang phân tích sở thích của bạn...',
              ),
              error: (e, _) => ErrorStateWidget(
                message: '$e',
                onRetry: () => ref.invalidate(recommendationsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withOpacity(0.12),
            AppColors.primary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.accent, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Dựa trên danh mục và tag bạn thường ghi nhận, cùng khoảng cách '
              'từ vị trí hiện tại.',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final String reason;
  final double? distanceMeters;

  const _ReasonChip({required this.reason, this.distanceMeters});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_rounded,
                  size: 13, color: AppColors.primaryDark),
              const SizedBox(width: 5),
              Text(
                'Gợi ý vì $reason',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
        if (distanceMeters != null) ...[
          const SizedBox(width: 8),
          Text(
            formatDistance(distanceMeters!),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

class _ServerOfflineBanner extends StatelessWidget {
  const _ServerOfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 17, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chưa kết nối được AI server — kiểm tra server Python đã chạy chưa.',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
