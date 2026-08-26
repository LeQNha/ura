import 'package:cloud_firestore/cloud_firestore.dart';

/// 1 điểm GPS trong hành trình Expedition.
///
/// Lưu trực tiếp làm array field trên document Expedition (không tách
/// subcollection riêng) — đúng hướng "giữ đơn giản" đã thống nhất từ
/// đầu, và với quy mô đồ án (1 buổi đi bộ vài giờ, cập nhật mỗi khi di
/// chuyển ~15m) số điểm route tối đa chỉ vài trăm, không chạm giới hạn
/// 1MB/document của Firestore.
class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    return RoutePoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class ExpeditionStatus {
  ExpeditionStatus._();

  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

/// Expedition entity — theo dõi 1 "chuyến thám hiểm" của user: quãng
/// đường di chuyển (route), thời lượng, và số Observation ghi nhận
/// được trong lúc đang thám hiểm.
class ExpeditionModel {
  final String id;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status; // xem ExpeditionStatus
  final List<RoutePoint> routePoints;
  final double distanceMeters;
  final int observationCount;

  const ExpeditionModel({
    required this.id,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.status = ExpeditionStatus.active,
    this.routePoints = const [],
    this.distanceMeters = 0,
    this.observationCount = 0,
  });

  bool get isActive => status == ExpeditionStatus.active;

  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  factory ExpeditionModel.fromMap(Map<String, dynamic> map, String id) {
    final endedAtRaw = map['endedAt'];
    return ExpeditionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      startedAt: _timestampToDate(map['startedAt']),
      endedAt: endedAtRaw is Timestamp ? endedAtRaw.toDate() : null,
      status: map['status'] as String? ?? ExpeditionStatus.active,
      routePoints: ((map['routePoints'] as List?) ?? [])
          .map((e) => RoutePoint.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      observationCount: (map['observationCount'] as num?)?.toInt() ?? 0,
    );
  }

  factory ExpeditionModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ExpeditionModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'status': status,
      'routePoints': routePoints.map((p) => p.toMap()).toList(),
      'distanceMeters': distanceMeters,
      'observationCount': observationCount,
    };
  }

  static DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
}
