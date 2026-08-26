import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../observation/services/category_service.dart';
import '../viewmodels/map_viewmodel.dart';

/// Bottom sheet chọn Category để lọc trên Map. Áp dụng ngay khi bấm
/// (không cần nút "Áp dụng" riêng) — vì đây là lọc client-side tức thì,
/// không có chi phí network để phải gom lại thành 1 lần submit.
class MapFilterSheet extends ConsumerWidget {
  const MapFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final filter = ref.watch(mapFilterProvider);
    final viewModel = ref.read(mapFilterProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFDAD7D0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lọc theo danh mục',
                    style: Theme.of(context).textTheme.titleLarge),
                if (filter.hasActiveFilters)
                  TextButton(
                    onPressed: viewModel.clearFilters,
                    child: const Text('Xóa bộ lọc'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Chưa có danh mục nào.'),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final selected =
                        filter.selectedCategoryIds.contains(cat.id);
                    return FilterChip(
                      label: Text('${cat.icon} ${cat.name}'),
                      selected: selected,
                      onSelected: (_) => viewModel.toggleCategory(cat.id),
                      selectedColor: AppColors.primary.withOpacity(0.18),
                      checkmarkColor: AppColors.primaryDark,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primaryDark : null,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Lỗi tải danh mục: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
