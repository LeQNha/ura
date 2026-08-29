import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/services/auth_service.dart';
import '../models/achievement_model.dart';

class AchievementService {
  final FirebaseFirestore _firestore;

  AchievementService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _achievementsRef =>
      _firestore.collection(FirestoreCollections.achievements);

  Stream<List<AchievementModel>> watchAchievements() {
    return _achievementsRef.snapshots().map(
          (snap) => snap.docs.map(AchievementModel.fromSnapshot).toList(),
        );
  }

  Future<List<AchievementModel>> getAchievementsOnce() async {
    final snap = await _achievementsRef.get();
    return snap.docs.map(AchievementModel.fromSnapshot).toList();
  }

  /// Ghi danh sách Achievement mặc định vào Firestore — cùng cách làm
  /// với CategoryService.seedDefaultCategories() (chỉ nên gọi khi
  /// collection đang trống).
  Future<void> seedDefaultAchievements() async {
    final batch = _firestore.batch();
    for (final item in DefaultAchievements.seed) {
      final docRef = _achievementsRef.doc();
      batch.set(docRef, item);
    }
    await batch.commit();
  }

  /// Tạo 1 Achievement đơn lẻ — dùng ở Admin Dashboard (Phase 7).
  Future<void> createAchievement({
    required String name,
    required String description,
    required String icon,
    required int xpReward,
    required String conditionType,
    required num conditionValue,
  }) async {
    await _achievementsRef.add({
      'name': name,
      'description': description,
      'icon': icon,
      'xpReward': xpReward,
      'conditionType': conditionType,
      'conditionValue': conditionValue,
    });
  }

  Future<void> deleteAchievement(String id) async {
    await _achievementsRef.doc(id).delete();
  }
}

final achievementServiceProvider = Provider<AchievementService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return AchievementService(firestore);
});

final achievementsStreamProvider =
    StreamProvider<List<AchievementModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<AchievementModel>[]);

  final service = ref.watch(achievementServiceProvider);
  return service.watchAchievements();
});
