import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại Mission — MVP chỉ làm 3/6 loại tài liệu liệt kê (12.4): Category,
/// Quantity, Distance. Bỏ Area/Discovery/Combination vì cần thiết kế
/// thêm UI chọn vùng địa lý — vượt phạm vi hợp lý của phase Polish.
class MissionType {
  MissionType._();

  static const String category = 'category'; // "Tạo N Observation thuộc Category X"
  static const String quantity = 'quantity'; // "Tạo N Observation bất kỳ"
  static const String distance = 'distance'; // "Đi bộ tổng N mét"
}

/// Mission entity (tài liệu 12.4 — Hidden in Plain Sight).
///
/// Khác với thiết kế đầy đủ trong tài liệu (Mission có Area + Condition
/// + Validation riêng), bản MVP này đơn giản hóa: tiến độ Mission được
/// tính TRỰC TIẾP từ chỉ số hiện có của user (observationCount,
/// totalDistanceMeters, hoặc đếm Observation theo category) — không
/// cần hệ thống "bắt đầu Mission rồi theo dõi từ mốc đó", user hoàn
/// thành Mission dựa trên TOÀN BỘ lịch sử của họ, kể cả trước khi thấy
/// Mission đó. Đánh đổi hợp lý để tránh phải xây thêm cơ chế theo dõi
/// tiến độ riêng theo từng Mission.
class MissionModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String type; // xem MissionType
  final String? targetCategoryId; // chỉ dùng khi type == category
  final String? targetCategoryName; // denormalized, chỉ để hiển thị
  final num targetValue; // số Observation (category/quantity) hoặc mét (distance)
  final int rewardXp;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    this.targetCategoryId,
    this.targetCategoryName,
    required this.targetValue,
    required this.rewardXp,
  });

  factory MissionModel.fromMap(Map<String, dynamic> map, String id) {
    return MissionModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '🎯',
      type: map['type'] as String? ?? MissionType.quantity,
      targetCategoryId: map['targetCategoryId'] as String?,
      targetCategoryName: map['targetCategoryName'] as String?,
      targetValue: (map['targetValue'] as num?) ?? 1,
      rewardXp: (map['rewardXp'] as num?)?.toInt() ?? 20,
    );
  }

  factory MissionModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MissionModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'type': type,
      'targetCategoryId': targetCategoryId,
      'targetCategoryName': targetCategoryName,
      'targetValue': targetValue,
      'rewardXp': rewardXp,
    };
  }

  String get unitLabel {
    if (type == MissionType.distance) {
      return targetValue >= 1000
          ? '${(targetValue / 1000).toStringAsFixed(1)} km'
          : '${targetValue.toInt()} m';
    }
    return '${targetValue.toInt()}';
  }
}
