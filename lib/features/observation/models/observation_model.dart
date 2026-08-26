import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

/// Observation entity — đúng theo field đã chốt ở tài liệu 8.17, cộng
/// thêm vài field DENORMALIZED (creatorUsername, creatorAvatarUrl,
/// categoryName, categoryIcon) để feed/card hiển thị được ngay không
/// cần fetch thêm User/Category cho từng item — quan trọng vì Map/Feed
/// có thể hiển thị hàng chục Observation cùng lúc, fetch riêng từng cái
/// sẽ rất chậm và tốn quota Firestore.
///
/// Đánh đổi của denormalization: nếu User đổi username/avatar, các
/// Observation cũ vẫn hiển thị tên/avatar CŨ cho đến khi được cập nhật
/// lại (không tự động đồng bộ). Chấp nhận được cho quy mô đồ án — có
/// thể ghi chú đây là "hướng cải tiến tương lai" trong báo cáo.
class ObservationModel {
  final String id;
  final String creatorId;
  final String creatorUsername;
  final String? creatorAvatarUrl;

  final String title;
  final String? description;
  final List<String> photos;

  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final List<String> tags;

  final double latitude;
  final double longitude;
  final String? address;

  final DateTime observedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String rarity; // xem ObservationRarity
  final String status; // xem ObservationStatus

  final int likeCount;
  final int commentCount;

  /// Liên kết tới Expedition nếu Observation này được tạo trong lúc
  /// đang có 1 chuyến thám hiểm active (Phase 3) — null nếu tạo độc
  /// lập, không thuộc chuyến nào.
  final String? expeditionId;

  const ObservationModel({
    required this.id,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorAvatarUrl,
    required this.title,
    this.description,
    required this.photos,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    this.tags = const [],
    required this.latitude,
    required this.longitude,
    this.address,
    required this.observedAt,
    required this.createdAt,
    required this.updatedAt,
    this.rarity = ObservationRarity.common,
    this.status = ObservationStatus.active,
    this.likeCount = 0,
    this.commentCount = 0,
    this.expeditionId,
  });

  factory ObservationModel.fromMap(Map<String, dynamic> map, String id) {
    return ObservationModel(
      id: id,
      creatorId: map['creatorId'] as String? ?? '',
      creatorUsername: map['creatorUsername'] as String? ?? 'unknown',
      creatorAvatarUrl: map['creatorAvatarUrl'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      photos: List<String>.from(map['photos'] as List? ?? []),
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      categoryIcon: map['categoryIcon'] as String? ?? '📦',
      tags: List<String>.from(map['tags'] as List? ?? []),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      address: map['address'] as String?,
      observedAt: _timestampToDate(map['observedAt']),
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
      rarity: map['rarity'] as String? ?? ObservationRarity.common,
      status: map['status'] as String? ?? ObservationStatus.active,
      likeCount: (map['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (map['commentCount'] as num?)?.toInt() ?? 0,
      expeditionId: map['expeditionId'] as String?,
    );
  }

  factory ObservationModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ObservationModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'creatorUsername': creatorUsername,
      'creatorAvatarUrl': creatorAvatarUrl,
      'title': title,
      'description': description,
      'photos': photos,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'tags': tags,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'observedAt': Timestamp.fromDate(observedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rarity': rarity,
      'status': status,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'expeditionId': expeditionId,
    };
  }

  String get coverPhoto => photos.isNotEmpty ? photos.first : '';

  static DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
}
