import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/services/auth_service.dart';
import '../models/observation_model.dart';
import '../repositories/observation_repository.dart';

/// Feed mới nhất — dùng cho Home (Phase 1, tạm thời thay Map).
///
/// ⚠️ Watch `authStateChangesProvider` trước khi bắn query — KHÔNG chỉ
/// để biết "đã login chưa", mà quan trọng hơn: tránh race condition
/// giữa lúc Firebase Auth xác nhận user và lúc token đó thật sự gắn
/// vào kết nối Firestore. Nếu bắn query ngay khi widget build (không
/// đợi bước này), lần đọc đầu tiên ngay sau khi đăng nhập/đăng ký có
/// thể bị Firestore từ chối với permission-denied dù rule hoàn toàn
/// đúng — vì đây là StreamProvider thường (không tự retry), lỗi sẽ bị
/// "kẹt" cho tới khi có gì đó làm provider này rebuild lại.
final observationFeedProvider = StreamProvider<List<ObservationModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<ObservationModel>[]);

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
