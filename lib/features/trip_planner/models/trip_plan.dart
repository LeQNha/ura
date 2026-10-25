import '../../observation/models/observation_model.dart';

/// 1 điểm dừng trong lộ trình được gợi ý.
class TripStop {
  final ObservationModel observation;
  final double distanceFromPreviousMeters;
  final Duration walkingTimeFromPrevious;

  /// Độ phù hợp với người dùng (0..100) do AI chấm. `null` khi lộ trình
  /// do bộ lập dự phòng trên máy tạo ra (không có cá nhân hóa).
  final int? matchPercent;

  /// Các lý do ngắn giải thích vì sao AI chọn điểm này. Rỗng với bộ lập
  /// dự phòng.
  final List<String> reasons;

  /// Dự kiến đến điểm này sau bao lâu kể từ lúc xuất phát. `null` nếu
  /// không có thông tin.
  final Duration? arriveAfter;

  const TripStop({
    required this.observation,
    required this.distanceFromPreviousMeters,
    required this.walkingTimeFromPrevious,
    this.matchPercent,
    this.reasons = const [],
    this.arriveAfter,
  });
}

/// Kết quả lập kế hoạch — 1 lộ trình (xuất phát → các điểm dừng theo
/// thứ tự → quay lại điểm xuất phát nếu [isRoundTrip]).
class TripPlan {
  final List<TripStop> stops;

  /// Tổng quãng đường (bao gồm chặng cuối quay về điểm xuất phát nếu
  /// là lộ trình khép kín) — không phải chỉ tổng khoảng cách giữa các
  /// điểm dừng.
  final double totalDistanceMeters;

  /// Tổng thời gian ước tính — gồm thời gian đi bộ + thời gian dừng lại
  /// quan sát ở mỗi điểm, cộng cả chặng đi bộ quay về nếu có.
  final Duration estimatedTotalDuration;

  /// `true` = lộ trình khép kín (quay lại điểm xuất phát), `false` =
  /// kết thúc tại điểm dừng cuối. Mặc định `true` để các nơi cũ (bộ lập
  /// lộ trình dự phòng `planTrip`) không cần thay đổi.
  final bool isRoundTrip;

  const TripPlan({
    required this.stops,
    required this.totalDistanceMeters,
    required this.estimatedTotalDuration,
    this.isRoundTrip = true,
  });

  bool get isEmpty => stops.isEmpty;
}
