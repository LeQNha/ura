import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../observation/models/observation_model.dart';
import '../models/trip_plan.dart';

/// Trip Planning (tài liệu 12.3 mở rộng, "Discovery Route") — thuật
/// toán THAM LAM (greedy) có nhìn trước, KHÔNG dùng OSRM Trip service
/// (tránh phải giải bài toán TSP tối ưu — không cần thiết cho quy mô
/// đồ án, đúng tinh thần "đừng làm thuật toán quá phức tạp" đã thống
/// nhất). Đây là hàm thuần túy — không phụ thuộc Firestore/Flutter
/// UI, dễ kiểm tra logic độc lập.

int _rarityScore(String rarity) {
  switch (rarity) {
    case ObservationRarity.uncommon:
      return 1;
    case ObservationRarity.rare:
      return 2;
    case ObservationRarity.veryRare:
      return 3;
    case ObservationRarity.common:
    default:
      return 0;
  }
}

/// Trọng số của từng tiêu chí trong công thức điểm hấp dẫn — đặt thành
/// hằng số riêng để dễ tinh chỉnh sau khi thử nghiệm thực tế, không
/// cần sửa vào giữa logic thuật toán.
const _rarityWeight = 10.0;
const _categoryWeight = 15.0;
const _popularityWeight = 1.0;
const _distanceWeight = 5.0;
const _maxPopularityBonus = 20;

/// Điểm hấp dẫn của 1 Observation, nhìn từ vị trí hiện tại của "người
/// đi" trong lộ trình (không phải từ điểm xuất phát cố định — điểm
/// này thay đổi ở mỗi bước của thuật toán tham lam bên dưới):
///
///   score = rarity×10 + categoryBonus×15 + popularity×1 − (distance_km)×5
///
/// `categoryBonus` chỉ cộng nếu Observation thuộc 1 trong các category
/// user chọn ưu tiên (hoặc cộng cho TẤT CẢ nếu user không chọn gì —
/// tức "không có sở thích cụ thể" thì mọi category đều bình đẳng).
double _score({
  required ObservationModel observation,
  required double distanceMeters,
  required Set<String> preferredCategoryIds,
}) {
  final rarity = _rarityScore(observation.rarity) * _rarityWeight;
  final categoryBonus = (preferredCategoryIds.isEmpty ||
          preferredCategoryIds.contains(observation.categoryId))
      ? _categoryWeight
      : 0.0;
  final popularity =
      observation.likeCount.clamp(0, _maxPopularityBonus) * _popularityWeight;
  final distancePenalty = (distanceMeters / 1000) * _distanceWeight;

  return rarity + categoryBonus + popularity - distancePenalty;
}

/// Lên kế hoạch 1 lộ trình khám phá khép kín, xuất phát và kết thúc
/// tại [start].
///
/// Mỗi bước, thuật toán chọn Observation có điểm hấp dẫn cao nhất
/// trong số các lựa chọn CÒN KỊP quay lại [start] trong [timeBudget] —
/// đây là bước "nhìn trước" (lookahead) duy nhất, giữ thuật toán đơn
/// giản nhưng vẫn đảm bảo lộ trình luôn khả thi về mặt thời gian.
///
/// ⚠️ Đây là heuristic, KHÔNG đảm bảo lộ trình ngắn nhất/điểm cao nhất
/// tuyệt đối (đó là bài toán TSP — cố ý không giải quyết chính xác).
TripPlan planTrip({
  required LatLng start,
  required List<ObservationModel> candidates,
  required Duration timeBudget,
  Set<String> preferredCategoryIds = const {},
  double walkingSpeedKmh = 4.5,
  Duration dwellTimePerStop = const Duration(minutes: 8),
  int maxStops = 6,
}) {
  final remaining = [...candidates];
  final stops = <TripStop>[];

  var current = start;
  var usedTime = Duration.zero;
  var totalDistance = 0.0;

  Duration walkingTime(double meters) {
    final hours = (meters / 1000) / walkingSpeedKmh;
    return Duration(seconds: (hours * 3600).round());
  }

  while (remaining.isNotEmpty && stops.length < maxStops) {
    ObservationModel? best;
    var bestScore = double.negativeInfinity;
    var bestDistance = 0.0;

    for (final candidate in remaining) {
      final distance = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        candidate.latitude,
        candidate.longitude,
      );

      // Kiểm tra khả thi: đi tới đây + dừng quan sát + đi thẳng về
      // điểm xuất phát có còn kịp ngân sách thời gian không.
      final distanceBackToStart = Geolocator.distanceBetween(
        candidate.latitude,
        candidate.longitude,
        start.latitude,
        start.longitude,
      );
      final projectedTime = usedTime +
          walkingTime(distance) +
          dwellTimePerStop +
          walkingTime(distanceBackToStart);
      if (projectedTime > timeBudget) continue;

      final score = _score(
        observation: candidate,
        distanceMeters: distance,
        preferredCategoryIds: preferredCategoryIds,
      );

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
        bestDistance = distance;
      }
    }

    if (best == null) break; // Không còn điểm nào khả thi trong ngân sách

    stops.add(TripStop(
      observation: best,
      distanceFromPreviousMeters: bestDistance,
      walkingTimeFromPrevious: walkingTime(bestDistance),
    ));

    usedTime += walkingTime(bestDistance) + dwellTimePerStop;
    totalDistance += bestDistance;
    current = LatLng(best.latitude, best.longitude);
    remaining.remove(best);
  }

  // Cộng thêm chặng cuối quay về điểm xuất phát vào tổng — lộ trình
  // thực tế là 1 vòng khép kín, không phải đi 1 chiều rồi bỏ đó.
  if (stops.isNotEmpty) {
    final last = stops.last.observation;
    final distanceBack = Geolocator.distanceBetween(
      last.latitude,
      last.longitude,
      start.latitude,
      start.longitude,
    );
    totalDistance += distanceBack;
    usedTime += walkingTime(distanceBack);
  }

  return TripPlan(
    stops: stops,
    totalDistanceMeters: totalDistance,
    estimatedTotalDuration: usedTime,
  );
}
