import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';

/// LikeService — lưu Like dạng subcollection
/// `observations/{id}/likes/{userId}` (document id = userId) thay vì
/// array field trên Observation.
///
/// Lý do dùng subcollection + doc id = userId (khác với Tag dùng array
/// field): Like có thể tăng không giới hạn theo thời gian (1 bài viral
/// có thể có hàng nghìn like), nhồi vào 1 document duy nhất sẽ chạm
/// giới hạn 1MB của Firestore. Dùng userId làm doc id còn giúp kiểm
/// tra "user X đã like chưa" bằng 1 lần đọc document trực tiếp (rẻ),
/// thay vì phải quét cả mảng.
class LikeService {
  final FirebaseFirestore _firestore;

  LikeService(this._firestore);

  DocumentReference<Map<String, dynamic>> _likeRef(
    String observationId,
    String userId,
  ) {
    return _firestore
        .collection(FirestoreCollections.observations)
        .doc(observationId)
        .collection('likes')
        .doc(userId);
  }

  DocumentReference<Map<String, dynamic>> _observationRef(String observationId) {
    return _firestore.collection(FirestoreCollections.observations).doc(observationId);
  }

  Stream<bool> watchIsLiked(String observationId, String userId) {
    return _likeRef(observationId, userId).snapshots().map((doc) => doc.exists);
  }

  /// Toggle like/unlike — dùng transaction để đảm bảo `likeCount` trên
  /// Observation luôn khớp chính xác với số document trong subcollection
  /// `likes`, kể cả khi nhiều user bấm like gần như cùng lúc.
  Future<void> toggleLike(String observationId, String userId) async {
    try {
      await _firestore.runTransaction((tx) async {
        final likeDoc = await tx.get(_likeRef(observationId, userId));
        final observationDoc = await tx.get(_observationRef(observationId));
        final currentCount =
            (observationDoc.data()?['likeCount'] as num?)?.toInt() ?? 0;

        if (likeDoc.exists) {
          tx.delete(_likeRef(observationId, userId));
          tx.update(_observationRef(observationId), {
            'likeCount': currentCount > 0 ? currentCount - 1 : 0,
          });
        } else {
          tx.set(_likeRef(observationId, userId), {
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
          tx.update(_observationRef(observationId), {
            'likeCount': currentCount + 1,
          });
        }
      });
    } catch (e) {
      throw AppException('Không thể cập nhật lượt thích: $e');
    }
  }
}

final likeServiceProvider = Provider<LikeService>((ref) {
  return LikeService(ref.watch(firestoreProvider));
});
