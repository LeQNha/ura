import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/expedition_model.dart';

class ExpeditionService {
  final FirebaseFirestore _firestore;

  ExpeditionService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _expeditionsRef =>
      _firestore.collection(FirestoreCollections.expeditions);

  Future<String> createExpedition(ExpeditionModel expedition) async {
    try {
      final docRef = await _expeditionsRef.add(expedition.toMap());
      return docRef.id;
    } catch (e) {
      throw AppException('Không thể bắt đầu Expedition: $e');
    }
  }

  /// Expedition đang active của 1 user (chỉ có tối đa 1 tại một thời
  /// điểm — được đảm bảo ở tầng Repository, không phải ở query này).
  /// Query 2 điều kiện bằng-nhau (==) không cần Composite Index trên
  /// Firestore, nên không phát sinh bước setup thêm nào.
  Stream<ExpeditionModel?> watchActiveExpedition(String userId) {
    return _expeditionsRef
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: ExpeditionStatus.active)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return ExpeditionModel.fromSnapshot(snap.docs.first);
    });
  }

  Stream<ExpeditionModel?> watchExpedition(String id) {
    return _expeditionsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ExpeditionModel.fromSnapshot(doc);
    });
  }

  /// Thêm 1 điểm route mới + cập nhật quãng đường lũy kế. Dùng
  /// arrayUnion để chỉ cần ghi (không cần đọc trước) — rẻ hơn về
  /// Firestore read quota. Mỗi điểm luôn có timestamp khác nhau nên
  /// không lo bị arrayUnion coi là trùng lặp rồi bỏ qua.
  Future<void> appendRoutePoint(
    String expeditionId,
    RoutePoint point,
    double totalDistanceMeters,
  ) async {
    try {
      await _expeditionsRef.doc(expeditionId).update({
        'routePoints': FieldValue.arrayUnion([point.toMap()]),
        'distanceMeters': totalDistanceMeters,
      });
    } catch (e) {
      throw AppException('Không thể cập nhật vị trí Expedition: $e');
    }
  }

  Future<void> completeExpedition(
    String id, {
    required DateTime endedAt,
    required double distanceMeters,
  }) async {
    try {
      await _expeditionsRef.doc(id).update({
        'status': ExpeditionStatus.completed,
        'endedAt': Timestamp.fromDate(endedAt),
        'distanceMeters': distanceMeters,
      });
    } catch (e) {
      throw AppException('Không thể kết thúc Expedition: $e');
    }
  }

  Future<void> cancelExpedition(String id) async {
    try {
      await _expeditionsRef.doc(id).update({
        'status': ExpeditionStatus.cancelled,
        'endedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw AppException('Không thể hủy Expedition: $e');
    }
  }

  Future<void> incrementObservationCount(String id) async {
    try {
      await _expeditionsRef.doc(id).update({
        'observationCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw AppException('Không thể cập nhật số Observation của Expedition: $e');
    }
  }
}

final expeditionServiceProvider = Provider<ExpeditionService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ExpeditionService(firestore);
});
