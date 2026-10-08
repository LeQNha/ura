import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/auth/views/forgot_password_page.dart';
import '../../features/auth/views/login_page.dart';
import '../../features/auth/views/register_page.dart';
import '../../features/auth/views/splash_page.dart';
import '../../features/admin/views/admin_dashboard_page.dart';
import '../../features/community/views/bookmarks_page.dart';
import '../../features/gamification/views/achievements_page.dart';
import '../../features/home/views/home_shell_page.dart';
import '../../features/mission/views/missions_page.dart';
import '../../features/observation/views/create_observation_page.dart';
import '../../features/observation/views/observation_detail_page.dart';
import '../../features/profile/views/profile_page.dart';
import '../../features/ai/views/recommendations_page.dart';

/// Danh sách route path — tập trung một chỗ để tránh gõ nhầm string
/// literal ở nhiều nơi khác nhau trong app.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const createObservation = '/create-observation';
  static const observationDetail = '/observation/:id';
  static const achievements = '/achievements';
  static const profile = '/profile/:id';
  static const admin = '/admin';
  static const bookmarks = '/bookmarks';
  static const missions = '/missions';
  static const recommendations = '/recommendations';
}

/// Route Guard: dùng authStateChangesProvider để quyết định redirect.
///
/// Logic:
/// - Đang ở Splash và chưa xác định được trạng thái auth → ở lại Splash.
/// - Chưa đăng nhập mà cố vào vùng cần login (/home...) → đá về /login.
/// - Đã đăng nhập mà cố vào /login, /register, / (splash) → đá về /home.
///
/// Đây chính là "Route Guard" đã đề cập trong tài liệu kiến trúc (19.9).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;

      // Chưa xác định được trạng thái (lần đầu mở app) → giữ ở Splash.
      if (isLoading) {
        return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthRoute = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword;

      if (!isLoggedIn && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isLoggedIn && (isAuthRoute || currentPath == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      return null; // Không cần redirect.
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeShellPage(),
      ),
      GoRoute(
        path: AppRoutes.createObservation,
        builder: (context, state) => const CreateObservationPage(),
      ),
      GoRoute(
        path: AppRoutes.observationDetail,
        builder: (context, state) => ObservationDetailPage(
          observationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementsPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => ProfilePage(
          userId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) => const BookmarksPage(),
      ),
      GoRoute(
        path: AppRoutes.missions,
        builder: (context, state) => const MissionsPage(),
      ),
      GoRoute(
        path: AppRoutes.recommendations,
        builder: (context, state) => const RecommendationsPage(),
      ),
    ],
  );
});

/// go_router cần một Listenable để biết KHI NÀO cần chạy lại redirect
/// (mỗi khi authStateChangesProvider phát ra giá trị mới). Riverpod
/// StreamProvider không tự là Listenable, nên bọc lại bằng class nhỏ này.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(this.ref) {
    ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
