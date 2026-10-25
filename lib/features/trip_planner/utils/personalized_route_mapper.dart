import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../ai/models/route_ai_models.dart';
import '../../observation/models/observation_model.dart';
import '../models/route_preferences.dart';
import '../models/trip_plan.dart';

/// Cầu nối giữa dữ liệu của app và server AI lập lộ trình:
///   - [buildPlanRouteRequest]: gom yêu cầu + sở thích ngầm + danh sách
///     địa điểm thành JSON gửi cho `POST /plan-route`.
///   - [tripPlanFromAi]: đổi kết quả của server thành [TripPlan] để dùng
///     lại bản đồ xem trước và các nút chỉ đường sẵn có.
///
/// Toàn bộ là hàm thuần túy (không gọi mạng, không phụ thuộc Firestore),
/// nên dễ đọc và dễ kiểm tra riêng.

/// Số địa điểm tối đa gửi lên server (server cho phép tối đa 500). Nếu
/// có nhiều hơn thì chỉ giữ các địa điểm gần điểm xuất phát nhất.
const int kRouteMaxCandidates = 300;

/// Thời gian dừng quan sát ở mỗi điểm (phút) — khớp `dwellTimePerStop`
/// mặc định của bộ lập lộ trình dự phòng `planTrip`.
const double kRouteDwellMinutes = 8;

/// Giữ lại tối đa [limit] địa điểm gần [start] nhất.
List<ObservationModel> nearestCandidates(
  LatLng start,
  List<ObservationModel> all, {
  int limit = kRouteMaxCandidates,
}) {
  if (all.length <= limit) return all;

  final entries = all
      .map((o) => MapEntry(
            o,
            Geolocator.distanceBetween(
              start.latitude,
              start.longitude,
              o.latitude,
              o.longitude,
            ),
          ))
      .toList();
  entries.sort((a, b) => a.value.compareTo(b.value));
  return entries.take(limit).map((e) => e.key).toList();
}

Map<String, dynamic> _candidateJson(ObservationModel o) => {
      'id': o.id,
      'latitude': o.latitude,
      'longitude': o.longitude,
      'category_id': o.categoryId,
      'category_name': o.categoryName,
      'title': o.title,
      'rarity': o.rarity,
      'tags': o.tags,
      'like_count': o.likeCount,
      'comment_count': o.commentCount,
    };

/// 1 mục lịch sử (bài đã đăng / đã lưu) — tín hiệu sở thích ngầm.
Map<String, dynamic> _historyJson(ObservationModel o) => {
      'id': o.id,
      'category_id': o.categoryId,
      'rarity': o.rarity,
      'tags': o.tags,
    };

/// Dựng JSON gửi cho `POST /plan-route`.
///
/// Có 2 nguồn thông tin về người dùng:
///   1. [preferences]: yêu cầu RÕ RÀNG họ vừa chọn trên màn hình.
///   2. Lịch sử NGẦM: các bài họ đã đăng (`creatorId == userId`) và đã
///      lưu ([bookmarkedIds]), lấy từ danh sách [candidates] đã tải sẵn.
///      Nhờ đó AI có thể hiểu sở thích ngay cả khi người dùng không
///      chọn gì.
Map<String, dynamic> buildPlanRouteRequest({
  required LatLng start,
  required RoutePreferences preferences,
  required List<ObservationModel> candidates,
  required String? userId,
  required Set<String> bookmarkedIds,
}) {
  final created = userId == null
      ? <ObservationModel>[]
      : candidates.where((o) => o.creatorId == userId).toList();
  final bookmarked =
      candidates.where((o) => bookmarkedIds.contains(o.id)).toList();

  final nearby = nearestCandidates(start, candidates);

  return {
    'start': {'latitude': start.latitude, 'longitude': start.longitude},
    'round_trip': preferences.roundTrip,
    'time_budget_minutes': preferences.timeBudgetMinutes,
    'walking_speed_kmh': preferences.pace.speedKmh,
    'dwell_minutes': kRouteDwellMinutes,
    'max_stops': preferences.maxStops,
    'preferences': {
      'category_ids': preferences.categoryIds.toList(),
      'tags': preferences.tags.toList(),
      'prefer_rarity': preferences.rarity.wireValue,
      'prefer_new_places': preferences.preferNewPlaces,
    },
    'signals': {
      'created': created.map(_historyJson).toList(),
      'bookmarked': bookmarked.map(_historyJson).toList(),
    },
    'candidates': nearby.map(_candidateJson).toList(),
    'strategy': 'personalized',
  };
}

/// Gợi ý các thẻ phổ biến nhất trong [observations] để người dùng bấm
/// chọn nhanh (thay vì phải tự gõ).
List<String> suggestTags(List<ObservationModel> observations, {int limit = 8}) {
  final counts = <String, int>{};
  for (final o in observations) {
    for (final raw in o.tags) {
      final tag = raw.trim().toLowerCase();
      if (tag.isEmpty) continue;
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return entries.take(limit).map((e) => e.key).toList();
}

Duration _minutes(double minutes) =>
    Duration(seconds: (minutes * 60).round());

/// Đổi kết quả của server AI thành [TripPlan] (giữ lại độ phù hợp, lý do
/// và thời điểm dự kiến đến của từng điểm dừng).
///
/// Điểm dừng nào không tìm thấy trong [candidates] sẽ bị bỏ qua (về lý
/// thuyết không xảy ra vì server chỉ chọn trong danh sách ta đã gửi).
TripPlan tripPlanFromAi(AiRoutePlan ai, List<ObservationModel> candidates) {
  final byId = {for (final o in candidates) o.id: o};

  final stops = <TripStop>[];
  for (final s in ai.stops) {
    final observation = byId[s.observationId];
    if (observation == null) continue;
    stops.add(TripStop(
      observation: observation,
      distanceFromPreviousMeters: s.legDistanceMeters,
      walkingTimeFromPrevious: _minutes(s.legMinutes),
      matchPercent: s.matchPercent,
      reasons: s.reasons,
      arriveAfter: _minutes(s.arriveAtMinute),
    ));
  }

  return TripPlan(
    stops: stops,
    totalDistanceMeters: ai.totalDistanceMeters,
    estimatedTotalDuration: _minutes(ai.totalMinutes),
    isRoundTrip: ai.returnsToStart,
  );
}
