import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/observation_model.dart';
import '../services/category_service.dart';
import '../viewmodels/edit_observation_viewmodel.dart';
import '../widgets/edit_photo_grid.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/tag_input.dart';

/// Form Chỉnh sửa Observation — mở qua `Navigator.push` trực tiếp từ
/// Observation Detail (giống ThenAndNowPage), không qua go_router URL,
/// vì cần truyền thẳng đối tượng [observation] đã có sẵn trong bộ nhớ
/// thay vì buộc phải fetch lại theo id qua tham số đường dẫn.
///
/// ⚠️ KHÔNG cho sửa vị trí (lat/lng/address) — giữ nguyên định vị gốc
/// lúc ghi nhận thực địa, tránh Observation "trôi" khỏi đúng vị trí
/// thật đã quan sát.
class EditObservationPage extends ConsumerStatefulWidget {
  final ObservationModel observation;

  const EditObservationPage({super.key, required this.observation});

  @override
  ConsumerState<EditObservationPage> createState() => _EditObservationPageState();
}

class _EditObservationPageState extends ConsumerState<EditObservationPage> {
  late final _titleController =
      TextEditingController(text: widget.observation.title);
  late final _descriptionController =
      TextEditingController(text: widget.observation.description ?? '');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final viewModel =
        ref.read(editObservationViewModelProvider(widget.observation).notifier);
    final success = await viewModel.save();
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thay đổi.')),
      );
    } else {
      final error =
          ref.read(editObservationViewModelProvider(widget.observation)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Không thể lưu, vui lòng thử lại.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editObservationViewModelProvider(widget.observation));
    final viewModel =
        ref.read(editObservationViewModelProvider(widget.observation).notifier);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa'),
        actions: [
          TextButton(
            onPressed: state.isSaving || !state.isValid ? null : _handleSave,
            child: state.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Ảnh', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          EditPhotoGrid(
            existingUrls: state.existingPhotoUrls,
            newFiles: state.newPhotoFiles,
            onRemoveExisting: viewModel.removeExistingPhoto,
            onRemoveNew: viewModel.removeNewPhoto,
            onAddFiles: viewModel.addPhotos,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            maxLength: AppConstants.titleMaxLength,
            decoration: const InputDecoration(labelText: 'Tiêu đề *'),
            onChanged: viewModel.setTitle,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLength: AppConstants.descriptionMaxLength,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Mô tả (tùy chọn)',
              alignLabelWithHint: true,
            ),
            onChanged: viewModel.setDescription,
          ),
          const SizedBox(height: 16),
          Text('Danh mục *', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final selected = state.category?.id == cat.id;
                return ChoiceChip(
                  label: Text('${cat.icon} ${cat.name}'),
                  selected: selected,
                  onSelected: (_) => viewModel.setCategory(cat),
                  selectedColor: AppColors.primary.withOpacity(0.18),
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primaryDark : null,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Lỗi tải danh mục: $e'),
          ),
          const SizedBox(height: 20),
          Text('Tag', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TagInput(
            tags: state.tags,
            onAdd: viewModel.addTag,
            onRemove: viewModel.removeTag,
          ),
          const SizedBox(height: 20),
          Text('Độ hiếm', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ObservationRarity.values.map((r) {
              final selected = state.rarity == r;
              return GestureDetector(
                onTap: () => viewModel.setRarity(r),
                child: Opacity(
                  opacity: selected ? 1 : 0.45,
                  child: RarityBadge(rarity: r),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primaryDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vị trí không thể chỉnh sửa để giữ đúng dữ liệu ghi nhận thực địa.',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
