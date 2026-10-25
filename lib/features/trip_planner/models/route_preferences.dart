/// Nhịp đi bộ của người dùng — quy ra tốc độ (km/h) gửi cho AI để tính
/// thời gian di chuyển giữa các điểm.
enum WalkingPace {
  slow('Thong thả', 3.5),
  normal('Vừa phải', 4.5),
  fast('Nhanh', 5.5);

  const WalkingPace(this.label, this.speedKmh);

  final String label;
  final double speedKmh;
}

/// Người dùng thích địa điểm hiếm hay phổ biến. [wireValue] khớp với
/// `prefer_rarity` của server AI.
enum RarityPreference {
  any('Không quan trọng', 'any'),
  rare('Ưu tiên hiếm', 'rare'),
  common('Ưu tiên phổ biến', 'common');

  const RarityPreference(this.label, this.wireValue);

  final String label;
  final String wireValue;
}

/// Toàn bộ yêu cầu RÕ RÀNG của người dùng cho 1 lần lập lộ trình.
///
/// Đây là phần "yêu cầu" trong "lộ trình phù hợp với yêu cầu và sở
/// thích". Phần "sở thích ngầm" (suy ra từ bài đã đăng/đã lưu) do
/// `buildPlanRouteRequest()` tự thu thập, không nằm ở đây.
class RoutePreferences {
  /// Tổng thời gian có (đi bộ + dừng quan sát), đơn vị phút.
  final int timeBudgetMinutes;

  /// Danh mục người dùng chọn ưu tiên. Rỗng = không chọn (AI sẽ dựa
  /// vào lịch sử, nếu có).
  final Set<String> categoryIds;

  /// Thẻ (tag) người dùng quan tâm.
  final Set<String> tags;

  final RarityPreference rarity;
  final WalkingPace pace;

  /// Số điểm dừng tối đa.
  final int maxStops;

  /// `true` = quay về điểm xuất phát; `false` = kết thúc ở điểm cuối.
  final bool roundTrip;

  /// `true` = ưu tiên chỗ người dùng chưa từng ghi nhận.
  final bool preferNewPlaces;

  const RoutePreferences({
    this.timeBudgetMinutes = 60,
    this.categoryIds = const <String>{},
    this.tags = const <String>{},
    this.rarity = RarityPreference.any,
    this.pace = WalkingPace.normal,
    this.maxStops = 6,
    this.roundTrip = true,
    this.preferNewPlaces = true,
  });

  RoutePreferences copyWith({
    int? timeBudgetMinutes,
    Set<String>? categoryIds,
    Set<String>? tags,
    RarityPreference? rarity,
    WalkingPace? pace,
    int? maxStops,
    bool? roundTrip,
    bool? preferNewPlaces,
  }) {
    return RoutePreferences(
      timeBudgetMinutes: timeBudgetMinutes ?? this.timeBudgetMinutes,
      categoryIds: categoryIds ?? this.categoryIds,
      tags: tags ?? this.tags,
      rarity: rarity ?? this.rarity,
      pace: pace ?? this.pace,
      maxStops: maxStops ?? this.maxStops,
      roundTrip: roundTrip ?? this.roundTrip,
      preferNewPlaces: preferNewPlaces ?? this.preferNewPlaces,
    );
  }
}
