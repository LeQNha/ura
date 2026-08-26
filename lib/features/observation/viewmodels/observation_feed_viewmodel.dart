import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/observation_model.dart';
import '../repositories/observation_repository.dart';

/// Feed mới nhất — dùng cho Home (Phase 1, tạm thời thay Map).
final observationFeedProvider = StreamProvider<List<ObservationModel>>((ref) {
  final repository = ref.watch(observationRepositoryProvider);
  return repository.watchLatestFeed();
});

/// Detail của 1 Observation cụ thể — dùng `.family` vì cần tham số id.
/// autoDispose để giải phóng listener khi rời màn Detail, tránh giữ
/// stream Firestore chạy ngầm mãi sau khi user đã back ra ngoài.
final observationDetailProvider = StreamProvider.family
    .autoDispose<ObservationModel?, String>((ref, observationId) {
  final repository = ref.watch(observationRepositoryProvider);
  return repository.watchObservation(observationId);
});
