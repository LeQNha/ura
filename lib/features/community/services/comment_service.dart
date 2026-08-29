import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/comment_model.dart';

class CommentService {
  final FirebaseFirestore _firestore;

  CommentService(this._firestore);

  CollectionReference<Map<String, dynamic>> _commentsRef(String observationId) {
    return _firestore
        .collection(FirestoreCollections.observations)
        .doc(observationId)
        .collection('comments');
  }

  DocumentReference<Map<String, dynamic>> _observationRef(String observationId) {
    return _firestore.collection(FirestoreCollections.observations).doc(observationId);
  }

  Stream<List<CommentModel>> watchComments(String observationId) {
    return _commentsRef(observationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(CommentModel.fromSnapshot).toList());
  }

  Future<void> addComment(String observationId, CommentModel comment) async {
    try {
      await _firestore.runTransaction((tx) async {
        final observationDoc = await tx.get(_observationRef(observationId));
        final currentCount =
            (observationDoc.data()?['commentCount'] as num?)?.toInt() ?? 0;

        tx.set(_commentsRef(observationId).doc(), comment.toMap());
        tx.update(_observationRef(observationId), {
          'commentCount': currentCount + 1,
        });
      });
    } catch (e) {
      throw AppException('Không thể gửi bình luận: $e');
    }
  }

  Future<void> deleteComment(String observationId, String commentId) async {
    try {
      await _firestore.runTransaction((tx) async {
        final observationDoc = await tx.get(_observationRef(observationId));
        final currentCount =
            (observationDoc.data()?['commentCount'] as num?)?.toInt() ?? 0;

        tx.delete(_commentsRef(observationId).doc(commentId));
        tx.update(_observationRef(observationId), {
          'commentCount': currentCount > 0 ? currentCount - 1 : 0,
        });
      });
    } catch (e) {
      throw AppException('Không thể xóa bình luận: $e');
    }
  }
}

final commentServiceProvider = Provider<CommentService>((ref) {
  return CommentService(ref.watch(firestoreProvider));
});
