import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';

/// AuthService — lớp Service duy nhất được phép gọi trực tiếp FirebaseAuth.
///
/// Theo phân biệt Repository vs Service đã thống nhất:
///   Service   = "Tôi muốn nói chuyện với Firebase."
///   Repository = "Tôi muốn đăng nhập user." (không cần biết Firebase làm sao)
///
/// Mọi FirebaseAuthException đều được bắt và convert sang AppException
/// ngay tại đây — các lớp phía trên (Repository, ViewModel) không bao giờ
/// thấy FirebaseAuthException.
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  /// Stream phát ra mỗi khi trạng thái đăng nhập thay đổi.
  /// Dùng cho go_router redirect (Phase 0) và sau này cho toàn app.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AppException('Không tìm thấy phiên đăng nhập.');
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthException(e);
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthService(auth);
});

/// Stream provider cho trạng thái đăng nhập — dùng để router biết
/// user đã login hay chưa (redirect logic ở app_router.dart).
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
