import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../ai/models/route_ai_models.dart';
import '../../ai/services/ai_service.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../community/repositories/community_repository.dart';
import '../../map/viewmodels/map_viewmodel.dart';
import '../../observation/models/observation_model.dart';
import '../models/route_preferences.dart';
import '../models/trip_plan.dart';
import '../utils/personalized_route_mapper.dart';
import '../utils/trip_planning.dart';

/// Trạng thái màn "Lên kế hoạch khám phá" (lộ trình cá nhân hóa).
class PersonalizedTripState {
  /// Yêu cầu người dùng đang chọn trên form.
  final RoutePreferences preferences;
  final bool isPlanning;
  final String? errorMessage;

  /// Thông báo nhẹ (không phải lỗi), ví dụ "đang dùng bộ lập dự phòng".
  final String? notice;

  /// Lộ trình kết quả (dùng chung cho cả AI lẫn bộ dự phòng).
  final TripPlan? plan;

  /// Kết quả đầy đủ của server AI (hồ sơ sở thích, thuật toán...). `null`
  /// khi lộ trình do bộ dự phòng trên máy tạo ra.
  final AiRouteResult? ai;

  final LatLng? start;

  const PersonalizedTripState({
    this.preferences = const RoutePreferences(),
    this.isPlanning = false,
    this.errorMessage,
    this.notice,
    this.plan,
    this.ai,
    this.start,
  });

  bool get hasResult => plan != null;

  /// Có lộ trình nhưng không phải do AI lập.
  bool get usedFallback => plan != null && ai == null;

  PersonalizedTripState copyWith({
    RoutePreferences? preferences,
    bool? isPlanning,
    String? errorMessage,
    String? notice,
    TripPlan? plan,
    AiRouteResult? ai,
    LatLng? start,
    bool clearError = false,
    bool clearNotice = false,
    bool clearResult = false,
  }) {
    return PersonalizedTripState(
      preferences: preferences ?? this.preferences,
      isPlanning: isPlanning ?? this.isPlanning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notice: clearNotice ? null : (notice ?? this.notice),
      plan: clearResult ? null : (plan ?? this.plan),
      ai: clearResult ? null : (ai ?? this.ai),
      start: clearResult ? null : (start ?? this.start),
    );
  }
}

/// Luồng xử lý:
///   1. Lấy vị trí GPS làm điểm xuất phát.
///   2. Gom địa điểm (đã tải sẵn ở `mapObservationsProvider`) + yêu cầu
///      của người dùng + lịch sử (bài đã đăng/đã lưu) → gửi server AI.
///   3. Server AI trả lộ trình cá nhân hóa kèm lý do → hiển thị.
///   4. Nếu server không phản hồi → chuyển sang `planTrip()` chạy ngay
///      trên máy (không cá nhân hóa) và báo cho người dùng biết. Nhờ vậy
///      tính năng không bao giờ "chết" chỉ vì server tắt.
class PersonalizedTripViewModel extends StateNotifier<PersonalizedTripState> {
  final Ref ref;

  PersonalizedTripViewModel(this.ref) : super(const PersonalizedTripState());

  void setPreferences(RoutePreferences preferences) {
    state = state.copyWith(preferences: preferences);
  }

  void reset() {
    state = state.copyWith(
      clearResult: true,
      clearError: true,
      clearNotice: true,
    );
  }

  Future<void> generate() async {
    if (state.isPlanning) return;

    state = state.copyWith(
      isPlanning: true,
      clearError: true,
      clearNotice: true,
      clearResult: true,
    );

    try {
      final start = await _locateUser();

      final candidates =
          ref.read(mapObservationsProvider).valueOrNull ?? <ObservationModel>[];
      if (candidates.isEmpty) {
        throw 'Chưa có Observation nào quanh đây để lập kế hoạch.';
      }

      final preferences = state.preferences;
      final user = ref.read(currentUserProvider).valueOrNull;
      final bookmarkedIds = await _loadBookmarkedIds(user?.id);

      final request = buildPlanRouteRequest(
        start: start,
        preferences: preferences,
        candidates: candidates,
        userId: user?.id,
        bookmarkedIds: bookmarkedIds,
      );
      final result = await ref.read(aiServiceProvider).planRoute(request);

      const noRouteMessage =
          'Không tìm được lộ trình phù hợp trong thời gian này. '
          'Thử tăng thời gian hoặc bỏ bớt bộ lọc.';

      TripPlan plan;
      AiRouteResult? ai;
      String? notice;

      if (result != null) {
        // Server có phản hồi. `ok == false` nghĩa là không có lộ trình phù
        // hợp (không phải lỗi kỹ thuật) nên KHÔNG chuyển sang bộ dự phòng.
        if (!result.ok || result.route.stops.isEmpty) {
          throw result.warnings.isNotEmpty
              ? result.warnings.join(' ')
              : noRouteMessage;
        }
        plan = tripPlanFromAi(result.route, candidates);
        if (plan.isEmpty) throw noRouteMessage;
        ai = result;
        if (result.warnings.isNotEmpty) notice = result.warnings.join(' ');
      } else {
        plan = planTrip(
          start: start,
          candidates: candidates,
          timeBudget: Duration(minutes: preferences.timeBudgetMinutes),
          preferredCategoryIds: preferences.categoryIds,
          walkingSpeedKmh: preferences.pace.speedKmh,
          maxStops: preferences.maxStops,
        );
        if (plan.isEmpty) throw noRouteMessage;
        notice = 'Máy chủ AI chưa phản hồi nên app dùng bộ lập lộ trình cơ '
            'bản trên máy: không cá nhân hóa theo lịch sử của bạn'
            '${preferences.roundTrip ? '' : ' và luôn quay về điểm xuất phát'}.';
      }

      if (!mounted) return;
      state = state.copyWith(
        isPlanning: false,
        plan: plan,
        ai: ai,
        start: start,
        notice: notice,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isPlanning: false, errorMessage: e.toString());
    }
  }

  /// Lấy vị trí hiện tại làm điểm xuất phát. Ném chuỗi thông báo tiếng
  /// Việt nếu không lấy được (cùng cách làm với các màn khác trong app).
  Future<LatLng> _locateUser() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Vui lòng bật GPS/Dịch vụ vị trí.';

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw 'Bạn cần cấp quyền vị trí để lập kế hoạch chuyến đi.';
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  /// Danh sách id bài người dùng đã lưu (bookmark). Lỗi hoặc quá chậm thì
  /// coi như chưa lưu gì — đây chỉ là tín hiệu sở thích phụ, không được
  /// chặn việc lập lộ trình.
  Future<Set<String>> _loadBookmarkedIds(String? userId) async {
    if (userId == null) return <String>{};
    try {
      final ids = await ref
          .read(communityRepositoryProvider)
          .watchBookmarkedIds(userId)
          .first
          .timeout(const Duration(seconds: 4));
      return ids.toSet();
    } catch (_) {
      return <String>{};
    }
  }
}

/// `autoDispose`: rời màn hình là bỏ toàn bộ lựa chọn và kết quả cũ, lần
/// mở sau bắt đầu lại từ form trống (giống `createObservationViewModelProvider`).
final personalizedTripViewModelProvider = StateNotifierProvider.autoDispose<
    PersonalizedTripViewModel, PersonalizedTripState>((ref) {
  return PersonalizedTripViewModel(ref);
});
