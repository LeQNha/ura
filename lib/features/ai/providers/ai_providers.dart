import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../map/viewmodels/map_viewmodel.dart';
import '../../observation/models/observation_model.dart';
import '../models/ai_models.dart';
import '../services/ai_service.dart';

/// Bật/tắt lớp hiển thị "Khu vực thú vị" trên bản đồ — mặc định TẮT
/// để bản đồ không bị rối ngay từ đầu, người dùng tự bật khi muốn.
final showInterestingAreasProvider = StateProvider<bool>((ref) => false);

/// Các khu vực thú vị, tính từ chính tập Observation mà bản đồ đang
/// có sẵn (`mapObservationsProvider`) — không tải lại dữ liệu từ
/// Firestore lần nữa.
///
/// Chỉ gọi server khi lớp hiển thị được bật, tránh gọi AI vô ích mỗi
/// lần mở tab Bản đồ.
final interestingAreasProvider =
    FutureProvider.autoDispose<List<InterestingArea>>((ref) async {
  final enabled = ref.watch(showInterestingAreasProvider);
  if (!enabled) return [];

  final observations = ref.watch(mapObservationsProvider).valueOrNull ?? [];
  if (observations.isEmpty) return [];

  return ref.watch(aiServiceProvider).findInterestingAreas(observations);
});

/// Kết quả gợi ý kèm sẵn Observation đầy đủ — gộp lại ở đây để màn
/// hình chỉ cần đọc 1 provider thay vì tự ghép 2 danh sách.
typedef RecommendedItem = ({
  Recommendation recommendation,
  ObservationModel observation,
});

/// Danh sách gợi ý cho user hiện tại.
///
/// Hồ sơ sở thích được suy ra từ chính các Observation mà user đã tạo
/// (danh mục + tag họ hay dùng) — đây là tín hiệu sở thích sẵn có,
/// không cần thêm bảng dữ liệu theo dõi hành vi nào. Đồng thời loại
/// bỏ chính các Observation của họ khỏi kết quả (không ai cần được
/// gợi ý thứ chính mình vừa đăng).
final recommendationsProvider =
    FutureProvider.autoDispose<List<RecommendedItem>>((ref) async {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return [];

  final all = ref.watch(mapObservationsProvider).valueOrNull ?? [];
  if (all.isEmpty) return [];

  final mine = all.where((o) => o.creatorId == currentUser.id).toList();
  final others = all.where((o) => o.creatorId != currentUser.id).toList();
  if (others.isEmpty) return [];

  // Vị trí hiện tại chỉ là "có thì tốt" — nếu không lấy được (chưa cấp
  // quyền, GPS tắt), thuật toán vẫn chạy, chỉ bỏ qua yếu tố khoảng cách.
  double? lat;
  double? lng;
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      lat = pos.latitude;
      lng = pos.longitude;
    }
  } catch (_) {
    // Bỏ qua có chủ đích — xem giải thích ở trên.
  }

  final results = await ref.watch(aiServiceProvider).recommend(
        candidates: others,
        likedCategoryIds: mine.map((o) => o.categoryId).toList(),
        likedTags: mine.expand((o) => o.tags).toList(),
        seenIds: mine.map((o) => o.id).toList(),
        userLatitude: lat,
        userLongitude: lng,
      );

  final byId = {for (final o in others) o.id: o};
  return results
      .where((r) => byId.containsKey(r.observationId))
      .map((r) => (recommendation: r, observation: byId[r.observationId]!))
      .toList();
});
