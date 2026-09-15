import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../map/views/map_page.dart';
import '../../scanner/views/scanner_page.dart';
import 'home_feed_page.dart';

/// Shell chứa 3 tab chính: Bản đồ, Khám phá/Feed, Quét (AR Scanner).
///
/// (Tab "Thám hiểm" đã bị gỡ bỏ theo yêu cầu — không làm tính năng
/// Expedition nữa.)
///
/// Dùng IndexedStack thay vì rebuild widget theo tab đang chọn — giữ
/// nguyên state của từng tab khi chuyển qua lại (vị trí camera trên
/// Map, bộ lọc đang chọn, vị trí scroll của Feed...), đúng hành vi
/// quen thuộc của các app bản đồ/mạng xã hội.
///
/// Mỗi tab tự quản lý Scaffold/AppBar/FAB riêng của nó — Shell này chỉ
/// lo phần điều hướng giữa các tab.
///
/// Index tab được lưu trong `selectedTabIndexProvider` (core/) thay vì
/// local State — để ScannerPage (một tab khác) có thể biết chính xác
/// khi nào nó đang thật sự hiển thị, từ đó bật/tắt camera đúng lúc mà
/// không phải phụ thuộc ngược vào file này. Lưu ý: `ScannerPage` có
/// hằng số `_scannerTabIndex` PHẢI khớp đúng vị trí của nó trong
/// `_tabs` bên dưới (hiện là index 2) — nếu sau này đổi lại thứ tự
/// tab, nhớ cập nhật hằng số đó trong scanner_page.dart.
class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key});

  static const _tabs = [
    MapPage(),
    HomeFeedPage(),
    ScannerPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            ref.read(selectedTabIndexProvider.notifier).state = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.center_focus_strong_outlined),
            selectedIcon: Icon(Icons.center_focus_strong),
            label: 'Quét',
          ),
        ],
      ),
    );
  }
}
