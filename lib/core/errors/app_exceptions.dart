import 'package:firebase_auth/firebase_auth.dart';

/// Exception dùng chung cho toàn app.
///
/// Lý do tạo class riêng thay vì ném thẳng FirebaseAuthException lên UI:
/// ViewModel/View không nên biết về Firebase — chỉ nên biết "có lỗi và
/// message là gì". Điều này giữ đúng nguyên tắc Repository/Service đã
/// thống nhất trong kiến trúc (ViewModel không cần biết Firestore/Firebase
/// query thế nào).
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Chuyển FirebaseAuthException thành AppException với message tiếng Việt
/// dễ hiểu cho người dùng cuối, thay vì hiện message kỹ thuật của Firebase.
AppException mapFirebaseAuthException(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return const AppException('Địa chỉ email không hợp lệ.',
          code: 'invalid-email');
    case 'user-disabled':
      return const AppException('Tài khoản này đã bị khóa.',
          code: 'user-disabled');
    case 'user-not-found':
      return const AppException('Không tìm thấy tài khoản với email này.',
          code: 'user-not-found');
    case 'wrong-password':
    case 'invalid-credential':
      return const AppException('Email hoặc mật khẩu không đúng.',
          code: 'wrong-password');
    case 'email-already-in-use':
      return const AppException('Email này đã được đăng ký.',
          code: 'email-already-in-use');
    case 'weak-password':
      return const AppException('Mật khẩu quá yếu, vui lòng chọn mật khẩu khác.',
          code: 'weak-password');
    case 'too-many-requests':
      return const AppException(
          'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.',
          code: 'too-many-requests');
    case 'network-request-failed':
      return const AppException(
          'Lỗi kết nối mạng. Vui lòng kiểm tra internet.',
          code: 'network-request-failed');
    default:
      return AppException('Đã có lỗi xảy ra: ${e.message}', code: e.code);
  }
}
