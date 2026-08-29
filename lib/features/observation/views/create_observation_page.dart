import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../gamification/widgets/gamification_dialogs.dart';
import '../services/category_service.dart';
import '../viewmodels/create_observation_viewmodel.dart';
import '../widgets/photo_picker_section.dart';
import '../widgets/rarity_badge.dart';
import '../widgets/tag_input.dart';

const _stepTitles = ['Ảnh', 'Vị trí', 'Thông tin', 'Xem lại'];

class CreateObservationPage extends ConsumerWidget {
  const CreateObservationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createObservationViewModelProvider);
    final viewModel = ref.read(createObservationViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitles[state.currentStep]),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmDiscard(context),
        ),
      ),
      body: Column(
        children: [
          _StepProgress(currentStep: state.currentStep),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Padding(
                key: ValueKey(state.currentStep),
                padding: const EdgeInsets.all(20),
                child: switch (state.currentStep) {
                  0 => _PhotosStep(state: state, viewModel: viewModel),
                  1 => _LocationStep(state: state, viewModel: viewModel),
                  2 => _InfoStep(state: state, viewModel: viewModel),
                  _ => _ReviewStep(state: state),
                },
              ),
            ),
          ),
          _BottomBar(state: state, viewModel: viewModel),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy tạo Observation?'),
        content: const Text('Toàn bộ thông tin bạn đã nhập sẽ bị mất.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục sửa')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Hủy bỏ', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) context.pop();
  }
}

class _StepProgress extends StatelessWidget {
  final int currentStep;

  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(_stepTitles.length, (i) {
          final active = i <= currentStep;
          return Expanded(
            child: Container(
              margin:
                  EdgeInsets.only(right: i == _stepTitles.length - 1 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final CreateObservationState state;
  final CreateObservationViewModel viewModel;

  const _BottomBar({required this.state, required this.viewModel});

  bool get _canProceed => switch (state.currentStep) {
        0 => state.isPhotosStepValid,
        1 => state.isLocationStepValid,
        2 => state.isInfoStepValid,
        _ => state.canSubmit,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: state.isSubmitting ? null : viewModel.previousStep,
                child: const Text('Quay lại'),
              ),
            ),
          if (state.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _PrimaryStepButton(
              state: state,
              viewModel: viewModel,
              enabled: _canProceed,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStepButton extends ConsumerWidget {
  final CreateObservationState state;
  final CreateObservationViewModel viewModel;
  final bool enabled;

  const _PrimaryStepButton({
    required this.state,
    required this.viewModel,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLastStep = state.currentStep == 3;

    return ElevatedButton(
      onPressed: !enabled || state.isSubmitting
          ? null
          : () async {
              if (!isLastStep) {
                viewModel.nextStep();
                return;
              }
              final currentUser = ref.read(currentUserProvider).valueOrNull;
              if (currentUser == null) return;

              final id = await viewModel.submit(currentUser);
              if (!context.mounted) return;

              if (id != null) {
                final result = ref
                    .read(createObservationViewModelProvider)
                    .gamificationResult;
                if (result != null) {
                  await showGamificationCelebrations(context, result);
                }
                if (!context.mounted) return;
                context.pushReplacement('/observation/$id');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref
                              .read(createObservationViewModelProvider)
                              .submitError ??
                          'Có lỗi xảy ra, vui lòng thử lại.',
                    ),
                  ),
                );
              }
            },
      child: state.isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(isLastStep ? 'Đăng Observation' : 'Tiếp tục'),
    );
  }
}

// ---------------------------------------------------------------------
// Step 1 — Photos
// ---------------------------------------------------------------------

class _PhotosStep extends StatelessWidget {
  final CreateObservationState state;
  final CreateObservationViewModel viewModel;

  const _PhotosStep({required this.state, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Ghi lại bằng hình ảnh',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Chụp hoặc chọn tối thiểu 1 ảnh, tối đa '
          '${AppConstants.maxPhotosPerObservation} ảnh. Ảnh đầu tiên sẽ '
          'là ảnh bìa.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        PhotoPickerSection(
          photos: state.photos,
          onPhotosPicked: viewModel.addPhotos,
          onRemove: viewModel.removePhotoAt,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 2 — Location
// ---------------------------------------------------------------------

class _LocationStep extends StatefulWidget {
  final CreateObservationState state;
  final CreateObservationViewModel viewModel;

  const _LocationStep({required this.state, required this.viewModel});

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  @override
  void initState() {
    super.initState();
    // Tự động lấy vị trí ngay khi vào bước này nếu chưa có — đỡ user
    // phải tự bấm nút, giống hành vi quen thuộc của các app field-work.
    if (!widget.state.hasLocation && !widget.state.isLocating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.viewModel.fetchCurrentLocation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return ListView(
      children: [
        Text('Xác định vị trí', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Vị trí GPS giúp Observation của bạn xuất hiện đúng chỗ trên bản đồ.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(
                state.hasLocation
                    ? Icons.location_on
                    : Icons.location_searching,
                color: AppColors.primary,
                size: 36,
              ),
              const SizedBox(height: 12),
              if (state.isLocating)
                const Text('Đang xác định vị trí...')
              else if (state.hasLocation) ...[
                Text(
                  '${state.latitude!.toStringAsFixed(6)}, '
                  '${state.longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                if (state.address != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    state.address!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ] else
                Text(
                  state.locationError ?? 'Chưa xác định được vị trí.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: state.isLocating
                    ? null
                    : widget.viewModel.fetchCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18),
                label: Text(state.hasLocation
                    ? 'Lấy lại vị trí'
                    : 'Lấy vị trí hiện tại'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Step 3 — Info
// ---------------------------------------------------------------------

class _InfoStep extends ConsumerStatefulWidget {
  final CreateObservationState state;
  final CreateObservationViewModel viewModel;

  const _InfoStep({required this.state, required this.viewModel});

  @override
  ConsumerState<_InfoStep> createState() => _InfoStepState();
}

class _InfoStepState extends ConsumerState<_InfoStep> {
  // Giữ controller cố định trong State (không tạo mới mỗi lần build) —
  // quan trọng để không làm gãy việc gõ dấu tiếng Việt (IME composing).
  // Nếu tạo TextEditingController mới mỗi build, con trỏ và trạng thái
  // gõ dở dang (vd đang gõ "ơ" bằng phím w) có thể bị mất giữa chừng.
  late final _titleController = TextEditingController(text: widget.state.title);
  late final _descriptionController =
      TextEditingController(text: widget.state.description);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final viewModel = widget.viewModel;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return ListView(
      children: [
        Text('Mô tả phát hiện của bạn',
            style: Theme.of(context).textTheme.titleLarge),
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
          data: (categories) {
            if (categories.isEmpty) {
              return const _EmptyCategoriesCard();
            }
            return Wrap(
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
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
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
        const SizedBox(height: 4),
        Text(
          'Theo đánh giá chủ quan của bạn — cộng đồng có thể đóng góp thêm sau.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
        const SizedBox(height: 20),
        Text('Thời điểm quan sát',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: state.observedAt,
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
              lastDate: DateTime.now(),
            );
            if (picked != null) viewModel.setObservedAt(picked);
          },
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(DateFormat('dd/MM/yyyy').format(state.observedAt)),
        ),
      ],
    );
  }
}

class _EmptyCategoriesCard extends ConsumerStatefulWidget {
  const _EmptyCategoriesCard();

  @override
  ConsumerState<_EmptyCategoriesCard> createState() =>
      _EmptyCategoriesCardState();
}

class _EmptyCategoriesCardState extends ConsumerState<_EmptyCategoriesCard> {
  bool _seeding = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chưa có danh mục nào trong hệ thống.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đây là thao tác chỉ cần làm 1 lần cho cả app (tạm thời thay '
            'cho Admin Dashboard chưa được xây).',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _seeding
                ? null
                : () async {
                    setState(() => _seeding = true);
                    await ref
                        .read(categoryServiceProvider)
                        .seedDefaultCategories();
                    if (mounted) setState(() => _seeding = false);
                  },
            child: _seeding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Khởi tạo danh mục mặc định'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Step 4 — Review
// ---------------------------------------------------------------------

class _ReviewStep extends StatelessWidget {
  final CreateObservationState state;

  const _ReviewStep({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('Xem lại trước khi đăng',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 20),
        if (state.photos.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(state.photos.first, fit: BoxFit.cover),
            ),
          ),
        const SizedBox(height: 16),
        Text(state.title, style: Theme.of(context).textTheme.headlineSmall),
        if (state.description.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(state.description,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 14),
        _ReviewRow(
          icon: Icons.category_outlined,
          label: state.category != null
              ? '${state.category!.icon} ${state.category!.name}'
              : '—',
        ),
        _ReviewRow(
          icon: Icons.diamond_outlined,
          label: ObservationRarity.label(state.rarity),
        ),
        _ReviewRow(
          icon: Icons.location_on_outlined,
          label: state.address ??
              (state.hasLocation
                  ? '${state.latitude!.toStringAsFixed(5)}, ${state.longitude!.toStringAsFixed(5)}'
                  : '—'),
        ),
        _ReviewRow(
          icon: Icons.event_outlined,
          label: DateFormat('dd/MM/yyyy').format(state.observedAt),
        ),
        _ReviewRow(
          icon: Icons.photo_library_outlined,
          label: '${state.photos.length} ảnh',
        ),
        if (state.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  state.tags.map((t) => Chip(label: Text('#$t'))).toList(),
            ),
          ),
        if (state.submitError != null) ...[
          const SizedBox(height: 16),
          Text(state.submitError!,
              style: const TextStyle(color: AppColors.error)),
        ],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReviewRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
