import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/services/auth_service.dart';
import '../models/mission_model.dart';

class MissionService {
  final FirebaseFirestore _firestore;

  MissionService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _missionsRef =>
      _firestore.collection(FirestoreCollections.missions);

  Stream<List<MissionModel>> watchMissions() {
    return _missionsRef.snapshots().map(
          (snap) => snap.docs.map(MissionModel.fromSnapshot).toList(),
        );
  }

  Future<void> seedDefaultMissions() async {
    final batch = _firestore.batch();
    for (final item in DefaultMissions.seed) {
      final docRef = _missionsRef.doc();
      batch.set(docRef, item);
    }
    await batch.commit();
  }

  Future<void> createMission(MissionModel mission) async {
    await _missionsRef.add(mission.toMap());
  }

  Future<void> deleteMission(String id) async {
    await _missionsRef.doc(id).delete();
  }

  /// Đếm số Observation của [userId] thuộc [categoryId] — dùng tính
  /// tiến độ Mission loại `category`. Lọc bằng-nhau thuần túy (không
  /// orderBy), không cần Composite Index.
  ///
  /// Dùng `.get()` rồi đếm `.length` thay vì aggregate query `.count()`
  /// (API mới hơn, chưa chắc tương thích mọi version SDK) — đánh đổi
  /// chấp nhận được vì số Observation/category của 1 user thường chỉ
  /// vài chục, không đáng kể về chi phí đọc.
  Future<int> countObservationsByCategory(
    String userId,
    String categoryId,
  ) async {
    final snap = await _firestore
        .collection(FirestoreCollections.observations)
        .where('creatorId', isEqualTo: userId)
        .where('categoryId', isEqualTo: categoryId)
        .where('status', isEqualTo: 'active')
        .get();
    return snap.docs.length;
  }

  // ---- Completed missions (subcollection users/{uid}/completedMissions) ----

  DocumentReference<Map<String, dynamic>> _completedRef(
    String userId,
    String missionId,
  ) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection('completedMissions')
        .doc(missionId);
  }

  Stream<List<String>> watchCompletedMissionIds(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection('completedMissions')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Future<bool> isMissionCompleted(String userId, String missionId) async {
    final doc = await _completedRef(userId, missionId).get();
    return doc.exists;
  }

  Future<void> markMissionCompleted(String userId, String missionId) async {
    await _completedRef(userId, missionId).set({
      'claimedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}

final missionServiceProvider = Provider<MissionService>((ref) {
  return MissionService(ref.watch(firestoreProvider));
});

final missionsStreamProvider = StreamProvider<List<MissionModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<MissionModel>[]);

  final service = ref.watch(missionServiceProvider);
  return service.watchMissions();
});
