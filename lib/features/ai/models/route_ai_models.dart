// Các model đọc kết quả của endpoint `POST /plan-route` (server AI mới).
//
// Khóa JSON dùng snake_case, khớp với `ai_route_server/app/schemas.py`.
// Mọi hàm `fromMap` đều "khoan dung": thiếu trường thì dùng giá trị mặc
// định thay vì ném lỗi, để thay đổi nhỏ phía server không làm hỏng app.
// Dữ liệu sai KIỂU (ví dụ chuỗi ở chỗ lẽ ra là số) sẽ ném lỗi, và
// `AiService.planRoute` sẽ bắt lại rồi trả về `null`.

double _asDouble(dynamic value, [double fallback = 0]) =>
    (value as num?)?.toDouble() ?? fallback;

int _asInt(dynamic value, [int fallback = 0]) =>
    (value as num?)?.toInt() ?? fallback;

String _asString(dynamic value, [String fallback = '']) =>
    (value as String?) ?? fallback;

List<String> _asStringList(dynamic value) =>
    ((value as List?) ?? const []).map((e) => e.toString()).toList();

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

/// Mức yêu thích của người dùng với 1 danh mục (0..1), do AI suy ra.
class AiCategoryAffinity {
  final String categoryId;
  final String categoryName;
  final double affinity;

  const AiCategoryAffinity({
    required this.categoryId,
    required this.categoryName,
    required this.affinity,
  });

  factory AiCategoryAffinity.fromMap(Map<String, dynamic> map) {
    return AiCategoryAffinity(
      categoryId: _asString(map['category_id']),
      categoryName: _asString(map['category_name']),
      affinity: _asDouble(map['affinity']),
    );
  }
}

/// "AI hiểu bạn thế nào" — hồ sơ sở thích được suy ra từ lựa chọn của
/// người dùng và lịch sử bài đã đăng/đã lưu.
class AiTasteProfile {
  final List<AiCategoryAffinity> topCategories;
  final List<String> topTags;

  /// Độ tin cậy của hồ sơ (0..1). Càng nhiều dữ liệu về người dùng
  /// càng cao.
  final double confidence;

  /// Nguồn thông tin: `explicit` (lựa chọn của người dùng), `history`
  /// (bài đã đăng/đã lưu), `default` (chưa có gì).
  final List<String> sources;

  /// `true` khi chưa có thông tin sở thích nào (người dùng mới): AI chỉ
  /// còn dựa vào độ phổ biến của địa điểm.
  final bool coldStart;

  const AiTasteProfile({
    required this.topCategories,
    required this.topTags,
    required this.confidence,
    required this.sources,
    required this.coldStart,
  });

  factory AiTasteProfile.fromMap(Map<String, dynamic> map) {
    return AiTasteProfile(
      topCategories: ((map['top_categories'] as List?) ?? const [])
          .map((e) => AiCategoryAffinity.fromMap(_asMap(e)))
          .toList(),
      topTags: ((map['top_tags'] as List?) ?? const [])
          .map((e) => _asString(_asMap(e)['tag']))
          .where((t) => t.isNotEmpty)
          .toList(),
      confidence: _asDouble(map['confidence']),
      sources: _asStringList(map['sources']),
      coldStart: (map['cold_start'] as bool?) ?? false,
    );
  }

  static const empty = AiTasteProfile(
    topCategories: [],
    topTags: [],
    confidence: 0,
    sources: [],
    coldStart: true,
  );
}

/// 1 điểm dừng do AI chọn, kèm lý do.
class AiRouteStop {
  final String observationId;
  final int order;
  final String title;
  final String categoryId;
  final String categoryName;
  final String rarity;
  final double latitude;
  final double longitude;

  /// Chặng đi từ điểm trước (hoặc điểm xuất phát) tới điểm này.
  final double legDistanceMeters;
  final double legMinutes;

  /// Dự kiến đến điểm này sau bao nhiêu phút kể từ lúc xuất phát.
  final double arriveAtMinute;
  final double dwellMinutes;

  /// Số phút đi bộ tăng thêm nếu ghé điểm này (so với bỏ qua nó).
  final double detourMinutes;

  /// Độ phù hợp với người dùng, 0..100.
  final int matchPercent;

  /// Các lý do ngắn (tiếng Việt) giải thích vì sao chọn điểm này.
  final List<String> reasons;

  const AiRouteStop({
    required this.observationId,
    required this.order,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.rarity,
    required this.latitude,
    required this.longitude,
    required this.legDistanceMeters,
    required this.legMinutes,
    required this.arriveAtMinute,
    required this.dwellMinutes,
    required this.detourMinutes,
    required this.matchPercent,
    required this.reasons,
  });

  factory AiRouteStop.fromMap(Map<String, dynamic> map) {
    return AiRouteStop(
      observationId: _asString(map['id']),
      order: _asInt(map['order']),
      title: _asString(map['title']),
      categoryId: _asString(map['category_id']),
      categoryName: _asString(map['category_name']),
      rarity: _asString(map['rarity'], 'common'),
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      legDistanceMeters: _asDouble(map['leg_distance_m']),
      legMinutes: _asDouble(map['leg_minutes']),
      arriveAtMinute: _asDouble(map['arrive_at_minute']),
      dwellMinutes: _asDouble(map['dwell_minutes']),
      detourMinutes: _asDouble(map['detour_minutes']),
      matchPercent: _asInt(map['match_percent']),
      reasons: _asStringList(map['reasons']),
    );
  }
}

/// Lộ trình do AI lập.
class AiRoutePlan {
  final List<AiRouteStop> stops;

  /// `loop` (quay về điểm xuất phát), `open` (kết thúc ở điểm cuối) hoặc
  /// `one_way` (kết thúc ở điểm đích chỉ định).
  final String mode;
  final bool returnsToStart;

  final double totalDistanceMeters;
  final double totalWalkMinutes;
  final double totalDwellMinutes;
  final double totalMinutes;
  final int timeBudgetMinutes;
  final double slackMinutes;

  /// Độ phù hợp trung bình của cả lộ trình (0..100).
  final int avgMatchPercent;
  final int distinctCategories;

  const AiRoutePlan({
    required this.stops,
    required this.mode,
    required this.returnsToStart,
    required this.totalDistanceMeters,
    required this.totalWalkMinutes,
    required this.totalDwellMinutes,
    required this.totalMinutes,
    required this.timeBudgetMinutes,
    required this.slackMinutes,
    required this.avgMatchPercent,
    required this.distinctCategories,
  });

  factory AiRoutePlan.fromMap(Map<String, dynamic> map) {
    return AiRoutePlan(
      stops: ((map['stops'] as List?) ?? const [])
          .map((e) => AiRouteStop.fromMap(_asMap(e)))
          .toList(),
      mode: _asString(map['mode'], 'loop'),
      returnsToStart: (map['returns_to_start'] as bool?) ?? true,
      totalDistanceMeters: _asDouble(map['total_distance_m']),
      totalWalkMinutes: _asDouble(map['total_walk_minutes']),
      totalDwellMinutes: _asDouble(map['total_dwell_minutes']),
      totalMinutes: _asDouble(map['total_minutes']),
      timeBudgetMinutes: _asInt(map['time_budget_minutes']),
      slackMinutes: _asDouble(map['slack_minutes']),
      avgMatchPercent: _asInt(map['avg_match_percent']),
      distinctCategories: _asInt(map['distinct_categories']),
    );
  }
}

/// Toàn bộ phản hồi của `/plan-route`.
class AiRouteResult {
  /// `false` = server không lập được lộ trình phù hợp (xem [warnings]).
  /// Đây không phải lỗi kỹ thuật.
  final bool ok;
  final AiRoutePlan route;
  final AiTasteProfile profile;
  final List<String> warnings;
  final String algorithm;
  final double runtimeMs;

  const AiRouteResult({
    required this.ok,
    required this.route,
    required this.profile,
    required this.warnings,
    required this.algorithm,
    required this.runtimeMs,
  });

  factory AiRouteResult.fromMap(Map<String, dynamic> map) {
    final meta = _asMap(map['meta']);
    return AiRouteResult(
      ok: (map['ok'] as bool?) ?? false,
      route: AiRoutePlan.fromMap(_asMap(map['route'])),
      profile: map['profile'] is Map
          ? AiTasteProfile.fromMap(_asMap(map['profile']))
          : AiTasteProfile.empty,
      warnings: _asStringList(map['warnings']),
      algorithm: _asString(meta['algorithm']),
      runtimeMs: _asDouble(meta['runtime_ms']),
    );
  }
}
