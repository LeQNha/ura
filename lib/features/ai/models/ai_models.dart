/// Các model tương ứng với dữ liệu AI Backend (Python) trả về.

/// 1 Observation bị nghi là trùng với ảnh vừa chụp.
class DuplicateMatch {
  final String observationId;
  final double similarity; // 0..1, càng gần 1 càng giống

  const DuplicateMatch({
    required this.observationId,
    required this.similarity,
  });

  factory DuplicateMatch.fromMap(Map<String, dynamic> map) {
    return DuplicateMatch(
      observationId: map['observation_id'] as String? ?? '',
      similarity: (map['similarity'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Phần trăm để hiển thị cho người dùng (vd "92% giống").
  int get similarityPercent => (similarity * 100).round();
}

/// Kết quả kiểm tra trùng lặp.
///
/// Luôn kèm [embedding] — kể cả khi không trùng — vì app cần lưu
/// vector này vào Firestore cùng Observation mới, để lần sau có cái mà
/// so sánh. Nhờ vậy chỉ cần gọi server 1 lần thay vì 2 lần (1 lần
/// check + 1 lần lấy embedding).
class DuplicateCheckResult {
  final bool isDuplicate;
  final DuplicateMatch? bestMatch;
  final List<DuplicateMatch> matches;
  final List<double> embedding;

  const DuplicateCheckResult({
    required this.isDuplicate,
    this.bestMatch,
    this.matches = const [],
    this.embedding = const [],
  });

  factory DuplicateCheckResult.fromMap(Map<String, dynamic> map) {
    final rawBest = map['best_match'] as Map<String, dynamic>?;
    return DuplicateCheckResult(
      isDuplicate: map['is_duplicate'] as bool? ?? false,
      bestMatch: rawBest == null ? null : DuplicateMatch.fromMap(rawBest),
      matches: ((map['matches'] as List?) ?? [])
          .map((e) => DuplicateMatch.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      embedding: ((map['embedding'] as List?) ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  /// Kết quả "rỗng" — dùng khi server không phản hồi được, để luồng
  /// tạo Observation vẫn chạy tiếp bình thường thay vì báo lỗi.
  static const DuplicateCheckResult empty =
      DuplicateCheckResult(isDuplicate: false);
}

/// 1 khu vực thú vị do thuật toán DBSCAN tìm ra.
class InterestingArea {
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final int observationCount;
  final int distinctCategories;
  final double score; // 0..1
  final List<String> observationIds;

  const InterestingArea({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    required this.observationCount,
    required this.distinctCategories,
    required this.score,
    this.observationIds = const [],
  });

  factory InterestingArea.fromMap(Map<String, dynamic> map) {
    return InterestingArea(
      centerLatitude: (map['centerLatitude'] as num?)?.toDouble() ?? 0,
      centerLongitude: (map['centerLongitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 0,
      observationCount: (map['observationCount'] as num?)?.toInt() ?? 0,
      distinctCategories: (map['distinctCategories'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      observationIds: ((map['observationIds'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  /// Xếp hạng độ thú vị để hiển thị — chia mức thay vì đưa số thô
  /// (0.4732) vốn vô nghĩa với người dùng cuối.
  String get tierLabel {
    if (score >= 0.6) return 'Rất đáng khám phá';
    if (score >= 0.4) return 'Đáng ghé qua';
    return 'Có vài thứ hay';
  }
}

/// 1 gợi ý từ hệ recommendation.
class Recommendation {
  final String observationId;
  final double score;
  final double? distanceMeters;
  final String reason;

  const Recommendation({
    required this.observationId,
    required this.score,
    this.distanceMeters,
    required this.reason,
  });

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    return Recommendation(
      observationId: map['observationId'] as String? ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble(),
      reason: map['reason'] as String? ?? '',
    );
  }
}
