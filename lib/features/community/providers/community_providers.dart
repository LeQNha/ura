import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/comment_model.dart';
import '../models/report_model.dart';
import '../repositories/community_repository.dart';

/// Các provider chỉ-đọc (StreamProvider) cho Community — action
/// (toggle like/follow, gửi comment, gửi report) được gọi trực tiếp từ
/// widget qua `ref.read(communityRepositoryProvider)`, không cần
/// ViewModel riêng vì các action này đơn giản (không có state phức tạp
/// hơn 1 cờ loading cục bộ), theo đúng pattern đã dùng ở các nút "seed
/// dữ liệu mặc định" từ Phase 1.

final isLikedProvider =
    StreamProvider.family.autoDispose<bool, String>((ref, observationId) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return Stream.value(false);
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchIsLiked(observationId, currentUser.id);
});

final commentsProvider = StreamProvider.family
    .autoDispose<List<CommentModel>, String>((ref, observationId) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<CommentModel>[]);

  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchComments(observationId);
});

final isFollowingProvider =
    StreamProvider.family.autoDispose<bool, String>((ref, targetUserId) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return Stream.value(false);
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchIsFollowing(currentUser.id, targetUserId);
});

/// Dùng cho Admin Dashboard — lấy TẤT CẢ report (không lọc status
/// trong query, xem giải thích trong report_service.dart).
final allReportsProvider = StreamProvider.autoDispose<List<ReportModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<ReportModel>[]);

  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchAllReports();
});

final isBookmarkedProvider =
    StreamProvider.family.autoDispose<bool, String>((ref, observationId) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return Stream.value(false);
  final repo = ref.watch(communityRepositoryProvider);
  return repo.watchIsBookmarked(currentUser.id, observationId);
});
