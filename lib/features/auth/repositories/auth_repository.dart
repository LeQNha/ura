import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exceptions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_firestore_service.dart';

/// AuthRepository — "Tôi muốn đăng ký/đăng nhập user."
///
/// Đây là lớp mà ViewModel sẽ gọi vào. ViewModel không cần biết bên dưới
/// có FirebaseAuth + Firestore riêng biệt — Repository lo việc phối hợp
/// giữa 2 Service đó (vd: khi Register, phải tạo Auth account TRƯỚC rồi
/// mới tạo Firestore user document).
class AuthRepository {
  final AuthService _authService;
  final UserFirestoreService _userFirestoreService;

  AuthRepository(this._authService, this._userFirestoreService);

  String? get currentUserId => _authService.currentUser?.uid;

  bool get isLoggedIn => _authService.currentUser != null;

  /// Đăng ký tài khoản mới.
  ///
  /// Luồng: tạo Firebase Auth account TRƯỚC (Firebase tự động đăng nhập
  /// ngay sau khi tạo) → sau đó mới kiểm tra username trùng và tạo User
  /// document trên Firestore.
  ///
  /// Lý do phải tạo Auth account trước rồi mới check username, thay vì
  /// check trước như "trực giác" thông thường: Firestore Security Rules
  /// yêu cầu `isSignedIn()` mới được đọc collection `users` (kể cả để
  /// query xem username có bị trùng không). Nếu check username khi CHƯA
  /// đăng nhập, Firestore sẽ từ chối với lỗi "permission denied" — đây
  /// chính là lỗi bạn gặp phải.
  ///
  /// Nếu username bị trùng, hoặc bước tạo Firestore document thất bại
  /// sau khi Auth account đã tạo thành công, ta rollback (xóa Auth
  /// account) để tránh để lại tài khoản "mồ côi" không có profile.
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw const AppException('Đăng ký thất bại, vui lòng thử lại.');
    }

    // Từ đây, user đã signed-in nên các query Firestore mới hợp lệ.
    final usernameTaken = await _userFirestoreService.isUsernameTaken(username);
    if (usernameTaken) {
      await _authService.deleteAccount();
      throw const AppException('Username này đã được sử dụng.');
    }

    final newUser = UserModel.newUser(
      id: uid,
      username: username,
      email: email,
    );

    try {
      await _userFirestoreService.createUserProfile(newUser);
    } catch (e) {
      // Rollback: tránh để lại Auth account không có profile tương ứng.
      await _authService.deleteAccount();
      rethrow;
    }

    return newUser;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    final uid = credential.user?.uid;
    if (uid == null) {
      throw const AppException('Đăng nhập thất bại, vui lòng thử lại.');
    }

    final profile = await _userFirestoreService.getUserProfile(uid);
    if (profile == null) {
      throw const AppException(
        'Không tìm thấy hồ sơ người dùng. Vui lòng liên hệ hỗ trợ.',
      );
    }

    return profile;
  }

  Future<void> logout() => _authService.signOut();

  Future<void> sendPasswordResetEmail(String email) =>
      _authService.sendPasswordResetEmail(email);

  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return _userFirestoreService.getUserProfile(uid);
  }

  Stream<UserModel?> watchCurrentUserProfile() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();
    return _userFirestoreService.watchUserProfile(uid);
  }

  Future<void> deleteAccount() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _userFirestoreService.deleteUserProfile(uid);
    await _authService.deleteAccount();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final userFirestoreService = ref.watch(userFirestoreServiceProvider);
  return AuthRepository(authService, userFirestoreService);
});
