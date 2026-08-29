import 'package:cloud_firestore/cloud_firestore.dart';

/// User entity — theo đúng field đã chốt trong tài liệu thiết kế (17.2).
///
/// Lưu ý: Authentication (email/password) do Firebase Authentication quản lý.
/// Document trong Firestore collection `users` chỉ lưu profile/application
/// data — không lưu password hay thông tin nhạy cảm.
///
/// Một vài field như observationCount/expeditionCount/followerCount có thể
/// tính bằng cách query đếm thay vì lưu trực tiếp, nhưng ở Phase 0 mình lưu
/// counter ngay trên User document để đơn giản (đọc nhanh, không cần
/// aggregation query). Có thể tối ưu lại ở phase Database nếu cần.
class UserModel {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String role; // 'user' | 'admin' — xem UserRole trong app_constants.dart
  final int xp;
  final int level;
  final int reputation;
  final int observationCount;
  final int expeditionCount;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Danh sách id các Achievement đã mở khóa (Phase 5) — lưu trực tiếp
  /// làm array field trên User document, không tách entity riêng, theo
  /// đúng hướng "giữ đơn giản" đã áp dụng cho Tag.
  final List<String> unlockedAchievementIds;

  /// Tổng quãng đường đã đi qua tất cả Expedition (mét) — dùng cho
  /// Achievement dạng "đi bộ tổng X km".
  final double totalDistanceMeters;

  /// Rarity cao nhất từng tìm được (Phase 5) — dùng cho Achievement
  /// dạng "tìm được 1 phát hiện Rare trở lên".
  final String bestRarityFound;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.role = 'user',
    this.xp = 0,
    this.level = 1,
    this.reputation = 0,
    this.observationCount = 0,
    this.expeditionCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.unlockedAchievementIds = const [],
    this.totalDistanceMeters = 0,
    this.bestRarityFound = 'common',
  });

  /// Tạo UserModel mới khi user vừa đăng ký — mọi số liệu bắt đầu từ 0.
  factory UserModel.newUser({
    required String id,
    required String username,
    required String email,
    String? displayName,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      username: username,
      email: email,
      displayName: displayName ?? username,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String?,
      role: map['role'] as String? ?? 'user',
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      reputation: (map['reputation'] as num?)?.toInt() ?? 0,
      observationCount: (map['observationCount'] as num?)?.toInt() ?? 0,
      expeditionCount: (map['expeditionCount'] as num?)?.toInt() ?? 0,
      followerCount: (map['followerCount'] as num?)?.toInt() ?? 0,
      followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
      unlockedAchievementIds:
          List<String>.from(map['unlockedAchievementIds'] as List? ?? []),
      totalDistanceMeters:
          (map['totalDistanceMeters'] as num?)?.toDouble() ?? 0,
      bestRarityFound: map['bestRarityFound'] as String? ?? 'common',
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'role': role,
      'xp': xp,
      'level': level,
      'reputation': reputation,
      'observationCount': observationCount,
      'expeditionCount': expeditionCount,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unlockedAchievementIds': unlockedAchievementIds,
      'totalDistanceMeters': totalDistanceMeters,
      'bestRarityFound': bestRarityFound,
    };
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? role,
    int? xp,
    int? level,
    int? reputation,
    int? observationCount,
    int? expeditionCount,
    int? followerCount,
    int? followingCount,
    DateTime? updatedAt,
    List<String>? unlockedAchievementIds,
    double? totalDistanceMeters,
    String? bestRarityFound,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      reputation: reputation ?? this.reputation,
      observationCount: observationCount ?? this.observationCount,
      expeditionCount: expeditionCount ?? this.expeditionCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      bestRarityFound: bestRarityFound ?? this.bestRarityFound,
    );
  }

  bool get isAdmin => role == 'admin';

  static DateTime _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }
}
