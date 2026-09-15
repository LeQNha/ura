import '../../observation/models/observation_model.dart';

/// 1 điểm dừng trong lộ trình được gợi ý.
class TripStop {
  final ObservationModel observation;
  final double distanceFromPreviousMeters;
  final Duration walkingTimeFromPrevious;

  const TripStop({
    required this.observation,
    required this.distanceFromPreviousMeters,
    required this.walkingTimeFromPrevious,
  });
}

/// Kết quả lập kế hoạch — 1 lộ trình khép kín (xuất phát → các điểm
/// dừng theo thứ tự → quay lại điểm xuất phát).
class TripPlan {
  final List<TripStop> stops;

  /// Tổng quãng đường CẢ VÒNG (bao gồm chặng cuối quay về điểm xuất
  /// phát) — không phải chỉ tổng khoảng cách giữa các điểm dừng.
  final double totalDistanceMeters;

  /// Tổng thời gian ước tính CẢ VÒNG — gồm thời gian đi bộ + thời gian
  /// dừng lại quan sát ở mỗi điểm (`dwellTimePerStop` trong
  /// `planTrip()`), cộng cả chặng đi bộ quay về.
  final Duration estimatedTotalDuration;

  const TripPlan({
    required this.stops,
    required this.totalDistanceMeters,
    required this.estimatedTotalDuration,
  });

  bool get isEmpty => stops.isEmpty;
}
