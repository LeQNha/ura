import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/achievement_model.dart';
import '../models/gamification_result.dart';
import '../services/achievement_service.dart';
import '../utils/level_utils.dart';

/// GamificationRepository — nơi duy nhất được phép cộng XP và mở khóa
/// Achievement cho user.
///
/// ⚠️ Lưu ý về giới hạn thiết kế: vì app không có backend/Cloud
/// Function riêng, việc cộng XP được thực hiện TRỰC TIẾP từ client
/// (chính user đó tự ghi XP của mình lên Firestore). Điều này có nghĩa
/// về mặt lý thuyết, 1 user có kỹ thuật đủ giỏi vẫn có thể tự sửa XP
/// của mình qua Firestore API trực tiếp (không qua giao diện app). Đây
/// là đánh đổi chấp nhận được cho 1 đồ án học thuật (không phải game
/// cạnh tranh/có tiền thật) — ghi chú rõ trong báo cáo nếu cần.
///
/// Mỗi lần cộng XP dùng 1-2 Firestore Transaction để đảm bảo tính đúng
/// đắn khi đọc-tính-ghi (level phụ thuộc vào tổng XP, không phải phép
/// cộng đơn thuần nên không dùng FieldValue.increment được).
class GamificationRepository {
  final FirebaseFirestore _firestore;
  final AchievementService _achievementService;

  GamificationRepository(this._firestore, this._achievementService);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection(FirestoreCollections.users).doc(userId);

  Future<GamificationResult> awardXpForObservation(
    String userId,
    String rarity,
  ) async {
    final bonus = switch (rarity) {
      ObservationRarity.uncommon => 5,
      ObservationRarity.rare => 15,
      ObservationRarity.veryRare => 30,
      _ => 0,
    };
    final xpGain = 10 + bonus;

    final stats =
        await _firestore.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(_userRef(userId));
      final data = snap.data() ?? {};

      final currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = (data['level'] as num?)?.toInt() ?? 1;
      final currentObsCount = (data['observationCount'] as num?)?.toInt() ?? 0;
      final currentBestRarity =
          data['bestRarityFound'] as String? ?? ObservationRarity.common;

      final newXp = currentXp + xpGain;
      final newLevel = levelForXp(newXp);
      final newBestRarity = rarityRank(rarity) > rarityRank(currentBestRarity)
          ? rarity
          : currentBestRarity;

      tx.update(_userRef(userId), {
        'xp': newXp,
        'level': newLevel,
        'observationCount': currentObsCount + 1,
        'bestRarityFound': newBestRarity,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return {
        'xp': newXp,
        'level': newLevel,
        'leveledUp': newLevel > currentLevel,
        'observationCount': currentObsCount + 1,
        'expeditionCount': (data['expeditionCount'] as num?)?.toInt() ?? 0,
        'bestRarityFound': newBestRarity,
        'totalDistanceMeters':
            (data['totalDistanceMeters'] as num?)?.toDouble() ?? 0,
      };
    });

    return _checkAchievementsAndFinalize(userId, stats);
  }

  /// Cộng XP "trần trụi" — không đi kèm cập nhật counter nào khác
  /// (observationCount/expeditionCount/...), không kiểm tra Achievement
  /// mới. Dùng cho các nguồn thưởng XP rời rạc như Mission reward
  /// (Phase 8) — tái sử dụng đúng logic tính Level (đọc-tính-ghi bằng
  /// Transaction) thay vì viết lại 1 bản riêng ở MissionRepository.
  Future<GamificationResult> awardBonusXp(String userId, int amount) async {
    final result =
        await _firestore.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(_userRef(userId));
      final data = snap.data() ?? {};
      final currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = (data['level'] as num?)?.toInt() ?? 1;

      final newXp = currentXp + amount;
      final newLevel = levelForXp(newXp);

      tx.update(_userRef(userId), {
        'xp': newXp,
        'level': newLevel,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return {
        'xp': newXp,
        'level': newLevel,
        'leveledUp': newLevel > currentLevel,
      };
    });

    return GamificationResult(
      xp: result['xp'] as int,
      level: result['level'] as int,
      leveledUp: result['leveledUp'] as bool,
    );
  }

  Future<GamificationResult> awardXpForExpedition(
    String userId,
    double distanceMeters,
  ) async {
    // Giới hạn bonus quãng đường tối đa +50 XP/chuyến — tránh 1 chuyến
    // đi cực dài "cày" XP mất cân bằng, vẫn phù hợp không có backend
    // kiểm soát chống gian lận.
    final distanceBonus = (distanceMeters / 100).floor().clamp(0, 50);
    final xpGain = 20 + distanceBonus;

    final stats =
        await _firestore.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(_userRef(userId));
      final data = snap.data() ?? {};

      final currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = (data['level'] as num?)?.toInt() ?? 1;
      final currentExpCount = (data['expeditionCount'] as num?)?.toInt() ?? 0;
      final currentDistance =
          (data['totalDistanceMeters'] as num?)?.toDouble() ?? 0;

      final newXp = currentXp + xpGain;
      final newLevel = levelForXp(newXp);
      final newDistance = currentDistance + distanceMeters;

      tx.update(_userRef(userId), {
        'xp': newXp,
        'level': newLevel,
        'expeditionCount': currentExpCount + 1,
        'totalDistanceMeters': newDistance,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return {
        'xp': newXp,
        'level': newLevel,
        'leveledUp': newLevel > currentLevel,
        'observationCount': (data['observationCount'] as num?)?.toInt() ?? 0,
        'expeditionCount': currentExpCount + 1,
        'bestRarityFound':
            data['bestRarityFound'] as String? ?? ObservationRarity.common,
        'totalDistanceMeters': newDistance,
      };
    });

    return _checkAchievementsAndFinalize(userId, stats);
  }

  /// Sau khi cộng XP cơ bản (từ Observation/Expedition), kiểm tra xem
  /// chỉ số mới có vừa đủ mở khóa Achievement nào chưa từng có không.
  /// Nếu có, cộng thêm XP thưởng từ Achievement đó bằng 1 transaction
  /// thứ hai (tách riêng để logic mỗi transaction đơn giản, dễ kiểm
  /// soát đúng-sai, thay vì gộp tất cả vào 1 transaction phức tạp).
  Future<GamificationResult> _checkAchievementsAndFinalize(
    String userId,
    Map<String, dynamic> stats,
  ) async {
    final baseResult = GamificationResult(
      xp: stats['xp'] as int,
      level: stats['level'] as int,
      leveledUp: stats['leveledUp'] as bool,
    );

    final achievements = await _achievementService.getAchievementsOnce();
    if (achievements.isEmpty) return baseResult;

    final userSnap = await _userRef(userId).get();
    final unlockedIds = List<String>.from(
      (userSnap.data()?['unlockedAchievementIds'] as List?) ?? [],
    );

    final newlyUnlocked = <AchievementModel>[];
    for (final achievement in achievements) {
      if (unlockedIds.contains(achievement.id)) continue;
      final met = achievement.isMetBy(
        observationCount: stats['observationCount'] as int,
        expeditionCount: stats['expeditionCount'] as int,
        bestRarityFound: stats['bestRarityFound'] as String,
        totalDistanceMeters: stats['totalDistanceMeters'] as double,
      );
      if (met) newlyUnlocked.add(achievement);
    }

    if (newlyUnlocked.isEmpty) return baseResult;

    final bonusXp = newlyUnlocked.fold<int>(0, (sum, a) => sum + a.xpReward);
    final newIds = [...unlockedIds, ...newlyUnlocked.map((a) => a.id)];

    final finalResult =
        await _firestore.runTransaction<Map<String, dynamic>>((tx) async {
      final snap = await tx.get(_userRef(userId));
      final data = snap.data() ?? {};
      final currentXp = (data['xp'] as num?)?.toInt() ?? 0;
      final currentLevel = (data['level'] as num?)?.toInt() ?? 1;

      final newXp = currentXp + bonusXp;
      final newLevel = levelForXp(newXp);

      tx.update(_userRef(userId), {
        'xp': newXp,
        'level': newLevel,
        'unlockedAchievementIds': newIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return {
        'xp': newXp,
        'level': newLevel,
        'leveledUp': newLevel > currentLevel,
      };
    });

    return GamificationResult(
      xp: finalResult['xp'] as int,
      level: finalResult['level'] as int,
      leveledUp: (finalResult['leveledUp'] as bool) || baseResult.leveledUp,
      newlyUnlocked: newlyUnlocked,
    );
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final achievementService = ref.watch(achievementServiceProvider);
  return GamificationRepository(firestore, achievementService);
});
