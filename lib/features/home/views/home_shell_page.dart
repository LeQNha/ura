import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../map/views/map_page.dart';
import '../../scanner/views/scanner_page.dart';
import 'home_feed_page.dart';

/// Shell chứa 3 tab chính: Bản đồ, Khám phá/Feed, Quét (AR Scanner).
///
/// Dùng IndexedStack để giữ state từng tab. Index tab lưu trong
/// `selectedTabIndexProvider` (core/).
///
/// ⚠️ `ScannerPage` có hằng số `_scannerTabIndex` PHẢI khớp vị trí của nó
/// trong `_tabs` (hiện là index 2) — nếu đổi thứ tự tab, cập nhật lại.
///
/// Bản nâng cấp giao diện: thay `NavigationBar` mặc định bằng thanh điều
/// hướng tùy biến — nền bo góc có bóng, mục đang chọn là "viên thuốc"
/// gradient amber kèm nhãn, mục còn lại chỉ hiện icon.
class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key});

  static const _tabs = [
    MapPage(),
    HomeFeedPage(),
    ScannerPage(),
  ];

  static const _items = [
    _NavItemData(
      icon: Icons.map_outlined,
      selectedIcon: Icons.map_rounded,
      label: 'Bản đồ',
    ),
    _NavItemData(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      label: 'Khám phá',
    ),
    _NavItemData(
      icon: Icons.center_focus_strong_outlined,
      selectedIcon: Icons.center_focus_strong_rounded,
      label: 'Quét',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: _BottomNavBar(
        items: _items,
        selectedIndex: selectedIndex,
        onSelected: (index) =>
            ref.read(selectedTabIndexProvider.notifier).state = index,
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _BottomNavBar extends StatelessWidget {
  final List<_NavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(color: AppColors.borderOf(brightness), width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.45 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    data: items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final inactive = AppColors.textSecondaryOf(brightness);

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 48,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(18),
              boxShadow: selected
                  ? AppColors.softShadow(
                      opacity: 0.30,
                      blur: 14,
                      offset: const Offset(0, 6),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? data.selectedIcon : data.icon,
                  size: 23,
                  color: selected ? Colors.white : inactive,
                ),
                if (selected) ...[
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
