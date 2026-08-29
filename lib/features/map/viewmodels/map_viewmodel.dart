import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/services/auth_service.dart';
import '../../observation/models/observation_model.dart';
import '../../observation/repositories/observation_repository.dart';

/// State cho bộ lọc trên Map: search theo tiêu đề/tag + lọc theo Category.
///
/// Đây là hướng "basic filter/search" đã thống nhất — lọc HOÀN TOÀN ở
/// client (không dùng geohash/geospatial query). Cách này chỉ hiệu quả
/// khi dữ liệu còn ở quy mô vài trăm-nghìn Observation trở xuống, đúng
/// với quy mô đồ án. Nếu app scale lớn hơn nhiều, đây sẽ là chỗ cần
/// nâng cấp lên geospatial indexing (đã ghi chú ở phase trước).
class MapFilterState {
  final String query;
  final Set<String> selectedCategoryIds;

  const MapFilterState({
    this.query = '',
    this.selectedCategoryIds = const {},
  });

  bool get hasActiveFilters =>
      query.trim().isNotEmpty || selectedCategoryIds.isNotEmpty;

  MapFilterState copyWith({String? query, Set<String>? selectedCategoryIds}) {
    return MapFilterState(
      query: query ?? this.query,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    );
  }
}

class MapFilterViewModel extends StateNotifier<MapFilterState> {
  MapFilterViewModel() : super(const MapFilterState());

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleCategory(String categoryId) {
    final updated = {...state.selectedCategoryIds};
    if (!updated.remove(categoryId)) updated.add(categoryId);
    state = state.copyWith(selectedCategoryIds: updated);
  }

  void clearFilters() => state = const MapFilterState();
}

final mapFilterProvider =
    StateNotifierProvider.autoDispose<MapFilterViewModel, MapFilterState>(
        (ref) => MapFilterViewModel());

/// Nguồn dữ liệu thô cho Map — lấy nhiều Observation hơn feed thường
/// (limit cao hơn) vì Map cần hiển thị tổng quan cả khu vực, không chỉ
/// vài tin mới nhất.
///
/// ⚠️ Đợi `authStateChangesProvider` xác nhận xong mới bắn query — xem
/// giải thích chi tiết ở observation_feed_viewmodel.dart (tránh race
/// condition permission-denied ngay sau khi đăng nhập/đăng ký).
final mapObservationsProvider =
    StreamProvider.autoDispose<List<ObservationModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<ObservationModel>[]);

  final repository = ref.watch(observationRepositoryProvider);
  return repository.watchLatestFeed(limit: 200);
});

/// Danh sách Observation sau khi áp dụng filter — đây là danh sách thật
/// sự được vẽ lên Map.
final filteredMapObservationsProvider =
    Provider.autoDispose<List<ObservationModel>>((ref) {
  final observationsAsync = ref.watch(mapObservationsProvider);
  final filter = ref.watch(mapFilterProvider);
  final observations = observationsAsync.valueOrNull ?? [];

  return observations.where((o) {
    if (filter.selectedCategoryIds.isNotEmpty &&
        !filter.selectedCategoryIds.contains(o.categoryId)) {
      return false;
    }
    if (filter.query.trim().isNotEmpty) {
      final q = filter.query.trim().toLowerCase();
      final matchesTitle = o.title.toLowerCase().contains(q);
      final matchesTag = o.tags.any((t) => t.toLowerCase().contains(q));
      if (!matchesTitle && !matchesTag) return false;
    }
    return true;
  }).toList();
});
