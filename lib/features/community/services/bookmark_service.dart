import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';

/// BookmarkService — lưu Observation vào "Bộ sưu tập" cá nhân.
///
/// Lưu dạng subcollection `users/{uid}/bookmarks/{observationId}` (doc
/// id = observationId, giống cách Like dùng doc id = userId) — vừa
/// chống lưu trùng, vừa kiểm tra "đã lưu chưa" bằng 1 lần đọc document.
///
/// Chỉ lưu {observationId, createdAt} — KHÔNG denormalize thêm dữ liệu
/// hiển thị (title/ảnh/...) vào đây như Observation làm với Category,
/// vì bookmark là danh sách riêng tư của từng user, không cần tối ưu
/// đọc hàng loạt cho nhiều người xem cùng lúc như Feed công khai. Khi
/// hiển thị "Bộ sưu tập", app đọc lại Observation gốc theo từng id —
/// chấp nhận được vì số lượng bookmark của 1 user thường chỉ vài chục.
class BookmarkService {
  final FirebaseFirestore _firestore;

  BookmarkService(this._firestore);

  CollectionReference<Map<String, dynamic>> _bookmarksRef(String userId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .collection('bookmarks');
  }

  Stream<bool> watchIsBookmarked(String userId, String observationId) {
    return _bookmarksRef(userId)
        .doc(observationId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Danh sách id đã lưu, sắp xếp mới nhất trước — dùng để hiển thị màn
  /// "Bộ sưu tập" (BookmarksPage tự đọc thêm Observation gốc theo id).
  Stream<List<String>> watchBookmarkedIds(String userId) {
    return _bookmarksRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  Future<void> toggleBookmark(String userId, String observationId) async {
    try {
      final ref = _bookmarksRef(userId).doc(observationId);
      final doc = await ref.get();
      if (doc.exists) {
        await ref.delete();
      } else {
        await ref.set({'createdAt': Timestamp.fromDate(DateTime.now())});
      }
    } catch (e) {
      throw AppException('Không thể cập nhật bộ sưu tập: $e');
    }
  }
}

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService(ref.watch(firestoreProvider));
});
