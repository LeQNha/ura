import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Service xử lý đọc/ghi User document trên Firestore.
///
/// Tách riêng khỏi AuthService vì đây là 2 hệ thống khác nhau:
/// AuthService lo việc xác thực (đăng nhập/đăng ký), còn Service này lo
/// việc lưu profile data. AuthRepository sẽ gọi cả hai service này.
class UserFirestoreService {
  final FirebaseFirestore _firestore;

  UserFirestoreService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(FirestoreCollections.users);

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _usersRef.doc(user.id).set(user.toMap());
    } catch (e) {
      throw AppException('Không thể tạo hồ sơ người dùng: $e');
    }
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    } catch (e) {
      throw AppException('Không thể tải hồ sơ người dùng: $e');
    }
  }

  /// Stream để UI tự cập nhật realtime khi profile thay đổi
  /// (vd XP tăng sau khi tạo Observation ở phase sau).
  Stream<UserModel?> watchUserProfile(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _usersRef.doc(userId).update(data);
    } catch (e) {
      throw AppException('Không thể cập nhật hồ sơ: $e');
    }
  }

  /// Kiểm tra username đã tồn tại chưa — dùng khi Register để tránh trùng.
  Future<bool> isUsernameTaken(String username) async {
    final query =
        await _usersRef.where('username', isEqualTo: username).limit(1).get();
    return query.docs.isNotEmpty;
  }

  Future<void> deleteUserProfile(String userId) async {
    try {
      await _usersRef.doc(userId).delete();
    } catch (e) {
      throw AppException('Không thể xóa hồ sơ: $e');
    }
  }

  /// Danh sách toàn bộ user — dùng cho Admin Dashboard (Phase 7).
  /// Không phân trang (chấp nhận được ở quy mô đồ án); nếu số user lớn
  /// hơn nhiều trong tương lai, đây là chỗ cần thêm phân trang.
  Stream<List<UserModel>> watchAllUsers() {
    return _usersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromSnapshot).toList());
  }

  /// Đổi role user (user ↔ admin) — chỉ Admin Dashboard gọi hàm này.
  /// Rule Firestore đã cho phép `isAdmin()` sửa mọi field của bất kỳ
  /// user nào (xem firestore.rules), nên không cần thêm điều kiện gì
  /// đặc biệt ở tầng code, chỉ cần đảm bảo UI chỉ hiện nút này cho Admin.
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _usersRef.doc(userId).update({
        'role': newRole,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw AppException('Không thể cập nhật vai trò người dùng: $e');
    }
  }
}

final userFirestoreServiceProvider = Provider<UserFirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserFirestoreService(firestore);
});

/// Xem profile của 1 user cụ thể theo id — dùng cho Profile page
/// (Phase 7). Khác với `currentUserProvider` (luôn là user đang đăng
/// nhập), provider này nhận id bất kỳ.
final userProfileProvider =
    StreamProvider.family.autoDispose<UserModel?, String>((ref, userId) {
  final service = ref.watch(userFirestoreServiceProvider);
  return service.watchUserProfile(userId);
});

/// Toàn bộ user — dùng cho Admin Dashboard (Phase 7).
final allUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<UserModel>[]);

  final service = ref.watch(userFirestoreServiceProvider);
  return service.watchAllUsers();
});
