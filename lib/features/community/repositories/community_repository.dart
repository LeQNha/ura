import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../models/comment_model.dart';
import '../models/report_model.dart';
import '../services/bookmark_service.dart';
import '../services/comment_service.dart';
import '../services/follow_service.dart';
import '../services/like_service.dart';
import '../services/report_service.dart';

/// Gộp 5 Service (Like/Comment/Follow/Report/Bookmark) vào 1
/// Repository — vì cả 5 đều nhỏ, dùng chung ở những màn hình chồng lấn
/// nhau (Detail cần cả Like+Comment+Report+Bookmark, Profile cần
/// Follow), tách riêng từng repository sẽ chỉ khiến ViewModel phải
/// import/inject nhiều thứ vụn vặt không cần thiết.
class CommunityRepository {
  final LikeService _likeService;
  final CommentService _commentService;
  final FollowService _followService;
  final ReportService _reportService;
  final BookmarkService _bookmarkService;

  CommunityRepository(
    this._likeService,
    this._commentService,
    this._followService,
    this._reportService,
    this._bookmarkService,
  );

  // ---- Like ----
  Stream<bool> watchIsLiked(String observationId, String userId) =>
      _likeService.watchIsLiked(observationId, userId);

  Future<void> toggleLike(String observationId, String userId) =>
      _likeService.toggleLike(observationId, userId);

  // ---- Comment ----
  Stream<List<CommentModel>> watchComments(String observationId) =>
      _commentService.watchComments(observationId);

  Future<void> addComment({
    required String observationId,
    required UserModel author,
    required String text,
  }) {
    final comment = CommentModel(
      id: '',
      authorId: author.id,
      authorUsername: author.username,
      authorAvatarUrl: author.avatarUrl,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    return _commentService.addComment(observationId, comment);
  }

  Future<void> deleteComment(String observationId, String commentId) =>
      _commentService.deleteComment(observationId, commentId);

  // ---- Follow ----
  Stream<bool> watchIsFollowing(String currentUserId, String targetUserId) =>
      _followService.watchIsFollowing(currentUserId, targetUserId);

  Future<void> toggleFollow(String currentUserId, String targetUserId) =>
      _followService.toggleFollow(currentUserId, targetUserId);

  // ---- Report ----
  Future<void> reportObservation({
    required String observationId,
    required String observationTitle,
    required UserModel reporter,
    required String reason,
  }) {
    final report = ReportModel(
      id: '',
      observationId: observationId,
      observationTitle: observationTitle,
      reporterId: reporter.id,
      reporterUsername: reporter.username,
      reason: reason,
      createdAt: DateTime.now(),
    );
    return _reportService.createReport(report);
  }

  Stream<List<ReportModel>> watchAllReports() =>
      _reportService.watchAllReports();

  Future<void> resolveReport(String reportId) =>
      _reportService.resolveReport(reportId);

  // ---- Bookmark ----
  Stream<bool> watchIsBookmarked(String userId, String observationId) =>
      _bookmarkService.watchIsBookmarked(userId, observationId);

  Stream<List<String>> watchBookmarkedIds(String userId) =>
      _bookmarkService.watchBookmarkedIds(userId);

  Future<void> toggleBookmark(String userId, String observationId) =>
      _bookmarkService.toggleBookmark(userId, observationId);
}

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(
    ref.watch(likeServiceProvider),
    ref.watch(commentServiceProvider),
    ref.watch(followServiceProvider),
    ref.watch(reportServiceProvider),
    ref.watch(bookmarkServiceProvider),
  );
});
