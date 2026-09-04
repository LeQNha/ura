import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../observation/models/observation_model.dart';
import '../../observation/repositories/observation_repository.dart';
import '../../observation/widgets/observation_card.dart';
import '../repositories/community_repository.dart';

/// Đọc danh sách id đã bookmark, rồi tải từng Observation gốc theo id
/// (song song qua Future.wait) — chấp nhận được vì số bookmark của 1
/// user thường chỉ vài chục (xem giải thích trong bookmark_service.dart).
final _bookmarkedObservationsProvider =
    StreamProvider.autoDispose<List<ObservationModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return Stream.value(<ObservationModel>[]);

  final communityRepo = ref.watch(communityRepositoryProvider);
  final observationRepo = ref.watch(observationRepositoryProvider);

  return communityRepo.watchBookmarkedIds(currentUser.id).asyncMap((ids) async {
    final results = await Future.wait(ids.map(observationRepo.getObservation));
    // Lọc bỏ Observation đã bị xóa (soft-delete) hoặc null — id vẫn còn
    // trong bookmark nhưng Observation gốc không còn tồn tại nữa.
    return results.whereType<ObservationModel>().toList();
  });
});

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(_bookmarkedObservationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bộ sưu tập')),
      body: bookmarksAsync.when(
        data: (observations) {
          if (observations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.bookmark_border,
              title: 'Chưa lưu Observation nào',
              subtitle: 'Bấm biểu tượng 🔖 trên 1 Observation để lưu vào đây.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
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
        loading: () => const LoadingStateWidget(),
        error: (e, _) => ErrorStateWidget(
          message: '$e',
          onRetry: () => ref.invalidate(_bookmarkedObservationsProvider),
        ),
      ),
    );
  }
}
