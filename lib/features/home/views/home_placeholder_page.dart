// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../core/constants/app_constants.dart';
// import '../../auth/viewmodels/auth_viewmodel.dart';

// /// Màn hình tạm thời sau khi đăng nhập thành công.
// ///
// /// Đây CHƯA phải Map screen thật (đó là Phase 2). Mục đích của file này
// /// chỉ là có một nơi để go_router điều hướng tới sau khi login, và để
// /// bạn xác nhận luồng Auth (login/register/logout) đã chạy đúng trước
// /// khi qua phase tiếp theo.
// class HomePlaceholderPage extends ConsumerWidget {
//   const HomePlaceholderPage({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final currentUser = ref.watch(currentUserProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text(AppConstants.appName)),
//       body: Center(
//         child: currentUser.when(
//           data: (user) {
//             if (user == null) {
//               return const Text('Không có dữ liệu người dùng.');
//             }
//             return Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.explore, size: 64),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Xin chào, ${user.displayName} 👋',
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 const SizedBox(height: 4),
//                 Text('@${user.username} · ${user.email}'),
//                 const SizedBox(height: 4),
//                 Text('Level ${user.level} · ${user.xp} XP'),
//                 const SizedBox(height: 24),
//                 Text(
//                   'Phase 0 hoàn tất ✅\n'
//                   'Map & Explore sẽ được thêm ở Phase tiếp theo.',
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.bodySmall,
//                 ),
//                 const SizedBox(height: 24),
//                 OutlinedButton.icon(
//                   onPressed: () =>
//                       ref.read(authViewModelProvider.notifier).logout(),
//                   icon: const Icon(Icons.logout),
//                   label: const Text('Đăng xuất'),
//                 ),
//               ],
//             );
//           },
//           loading: () => const CircularProgressIndicator(),
//           error: (error, _) => Text('Lỗi: $error'),
//         ),
//       ),
//     );
//   }
// }
