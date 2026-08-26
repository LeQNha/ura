import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart' show authStateChangesProvider;

/// AuthViewModel quản lý state cho các action: login / register / logout /
/// forgot password.
///
/// Dùng AsyncNotifier để tự động có 3 trạng thái (loading/data/error) mà
/// không phải tự viết boilerplate — UI chỉ cần switch theo AsyncValue.
///
/// Lưu ý: đây là ViewModel cho các HÀNH ĐỘNG auth (login/register...),
/// khác với việc "user hiện tại đang là ai" — phần đó nằm ở
/// [currentUserProvider] bên dưới, lấy từ authStateChanges + Firestore.
class AuthViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Không cần load gì lúc khởi tạo — chỉ là notifier cho action.
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.login(email: email, password: password),
    );

    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);

    return !state.hasError;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.register(
        username: username,
        email: email,
        password: password,
      ),
    );

    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);

    return !state.hasError;
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    final repository = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(
      () => repository.sendPasswordResetEmail(email),
    );

    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);

    return !state.hasError;
  }
}

final authViewModelProvider =
    AsyncNotifierProvider<AuthViewModel, void>(AuthViewModel.new);

/// Provider cho biết user hiện tại là ai (profile đầy đủ từ Firestore),
/// tự động cập nhật realtime. Dùng ở khắp app (vd hiển thị avatar, kiểm
/// tra quyền Admin...), không chỉ riêng feature Auth.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  // Theo dõi authStateChanges để re-subscribe watchCurrentUserProfile
  // mỗi khi user login/logout (đổi uid).
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return repository.watchCurrentUserProfile();
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
