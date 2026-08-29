import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/level_utils.dart';

/// Loại điều kiện mở khóa Achievement — khớp với `conditionType` trong
/// DefaultAchievements.seed (app_constants.dart).
class AchievementConditionType {
  AchievementConditionType._();

  static const String observationCount = 'observationCount';
  static const String expeditionCount = 'expeditionCount';
  static const String rarityFound = 'rarityFound';
  static const String totalDistance = 'totalDistance';
}

/// Achievement entity — điều kiện mở khóa được biểu diễn đơn giản bằng
/// 1 cặp (conditionType, conditionValue) thay vì hệ thống rule phức
/// tạp, đủ dùng cho quy mô "Gamification cơ bản" của Phase này.
class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;
  final String conditionType;
  final num conditionValue;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.conditionType,
    required this.conditionValue,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map, String id) {
    return AchievementModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '🏅',
      xpReward: (map['xpReward'] as num?)?.toInt() ?? 0,
      conditionType: map['conditionType'] as String? ?? '',
      conditionValue: (map['conditionValue'] as num?) ?? 0,
    );
  }

  factory AchievementModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return AchievementModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'xpReward': xpReward,
      'conditionType': conditionType,
      'conditionValue': conditionValue,
    };
  }

  /// Kiểm tra 1 bộ chỉ số user hiện tại có đáp ứng điều kiện mở khóa
  /// Achievement này không.
  bool isMetBy({
    required int observationCount,
    required int expeditionCount,
    required String bestRarityFound,
    required double totalDistanceMeters,
  }) {
    switch (conditionType) {
      case AchievementConditionType.observationCount:
        return observationCount >= conditionValue;
      case AchievementConditionType.expeditionCount:
        return expeditionCount >= conditionValue;
      case AchievementConditionType.rarityFound:
        return rarityRank(bestRarityFound) >= conditionValue;
      case AchievementConditionType.totalDistance:
        return totalDistanceMeters >= conditionValue;
      default:
        return false;
    }
  }
}
