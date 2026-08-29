import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';

/// FollowService — quan hệ Follow lưu ở 2 subcollection song song:
/// `users/{me}/following/{targetId}` và `users/{target}/followers/{myId}`.
///
/// Lý do lưu 2 chiều thay vì 1: Firestore không hỗ trợ query kiểu SQL
/// JOIN. Nếu chỉ lưu 1 chiều (vd chỉ "following"), muốn biết "ai đang
/// follow tôi" sẽ phải quét TOÀN BỘ user khác — không khả thi. Lưu cả
/// 2 chiều giúp cả 2 câu hỏi ("tôi follow ai" / "ai follow tôi") đều
/// chỉ cần đọc thẳng 1 subcollection, đổi lại phải ghi 2 lần mỗi khi
/// follow/unfollow (chấp nhận được, thao tác này không xảy ra thường
/// xuyên như like/comment).
class FollowService {
  final FirebaseFirestore _firestore;

  FollowService(this._firestore);

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection(FirestoreCollections.users).doc(userId);

  DocumentReference<Map<String, dynamic>> _followingRef(
    String userId,
    String targetId,
  ) =>
      _userRef(userId).collection('following').doc(targetId);

  DocumentReference<Map<String, dynamic>> _followerRef(
    String userId,
    String followerId,
  ) =>
      _userRef(userId).collection('followers').doc(followerId);

  Stream<bool> watchIsFollowing(String currentUserId, String targetUserId) {
    return _followingRef(currentUserId, targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleFollow(String currentUserId, String targetUserId) async {
    if (currentUserId == targetUserId) {
      throw const AppException('Không thể tự follow chính mình.');
    }

    try {
      await _firestore.runTransaction((tx) async {
        final followingDoc =
            await tx.get(_followingRef(currentUserId, targetUserId));
        final currentUserDoc = await tx.get(_userRef(currentUserId));
        final targetUserDoc = await tx.get(_userRef(targetUserId));

        final myFollowingCount =
            (currentUserDoc.data()?['followingCount'] as num?)?.toInt() ?? 0;
        final targetFollowerCount =
            (targetUserDoc.data()?['followerCount'] as num?)?.toInt() ?? 0;

        if (followingDoc.exists) {
          tx.delete(_followingRef(currentUserId, targetUserId));
          tx.delete(_followerRef(targetUserId, currentUserId));
          tx.update(_userRef(currentUserId), {
            'followingCount': myFollowingCount > 0 ? myFollowingCount - 1 : 0,
          });
          tx.update(_userRef(targetUserId), {
            'followerCount':
                targetFollowerCount > 0 ? targetFollowerCount - 1 : 0,
          });
        } else {
          final now = Timestamp.fromDate(DateTime.now());
          tx.set(_followingRef(currentUserId, targetUserId), {'createdAt': now});
          tx.set(_followerRef(targetUserId, currentUserId), {'createdAt': now});
          tx.update(_userRef(currentUserId), {
            'followingCount': myFollowingCount + 1,
          });
          tx.update(_userRef(targetUserId), {
            'followerCount': targetFollowerCount + 1,
          });
        }
      });
    } catch (e) {
      throw AppException('Không thể cập nhật follow: $e');
    }
  }
}

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService(ref.watch(firestoreProvider));
});
