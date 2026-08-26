import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/observation_model.dart';

class ObservationService {
  final FirebaseFirestore _firestore;

  ObservationService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _observationsRef =>
      _firestore.collection(FirestoreCollections.observations);

  Future<String> createObservation(ObservationModel observation) async {
    try {
      final docRef = await _observationsRef.add(observation.toMap());
      return docRef.id;
    } catch (e) {
      throw AppException('Không thể tạo Observation: $e');
    }
  }

  Future<ObservationModel?> getObservation(String id) async {
    try {
      final doc = await _observationsRef.doc(id).get();
      if (!doc.exists) return null;
      return ObservationModel.fromSnapshot(doc);
    } catch (e) {
      throw AppException('Không thể tải Observation: $e');
    }
  }

  Stream<ObservationModel?> watchObservation(String id) {
    return _observationsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ObservationModel.fromSnapshot(doc);
    });
  }

  /// Feed mới nhất — dùng cho Home tạm thời ở Phase 1 (trước khi có Map
  /// ở Phase 2). Giới hạn [limit] để tránh tải quá nhiều cùng lúc.
  Stream<List<ObservationModel>> watchLatestFeed({int limit = 30}) {
    return _observationsRef
        .where('status', isEqualTo: ObservationStatus.active)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ObservationModel.fromSnapshot).toList());
  }

  /// Danh sách Observation được ghi nhận trong 1 Expedition cụ thể —
  /// dùng cho Expedition Summary. Lọc bằng-nhau (==) đơn thuần, không
  /// cần Composite Index.
  Future<List<ObservationModel>> getObservationsForExpedition(
    String expeditionId,
  ) async {
    try {
      final snap = await _observationsRef
          .where('expeditionId', isEqualTo: expeditionId)
          .where('status', isEqualTo: ObservationStatus.active)
          .get();
      return snap.docs.map(ObservationModel.fromSnapshot).toList();
    } catch (e) {
      throw AppException('Không thể tải Observation của Expedition: $e');
    }
  }

  Future<void> updateObservation(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _observationsRef.doc(id).update(data);
    } catch (e) {
      throw AppException('Không thể cập nhật Observation: $e');
    }
  }

  /// Soft delete theo đúng thiết kế ở tài liệu 8.3 — chỉ đổi status,
  /// không xóa vật lý document, để tránh mất dữ liệu và thuận tiện cho
  /// việc khôi phục/moderation sau này.
  Future<void> softDeleteObservation(String id) async {
    await updateObservation(id, {'status': ObservationStatus.deleted});
  }
}

final observationServiceProvider = Provider<ObservationService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ObservationService(firestore);
});
