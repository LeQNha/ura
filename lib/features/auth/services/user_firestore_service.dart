import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/user_model.dart';

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

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
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
}

final userFirestoreServiceProvider = Provider<UserFirestoreService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return UserFirestoreService(firestore);
});
