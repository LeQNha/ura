import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../models/category_model.dart';
import '../models/observation_model.dart';
import '../repositories/observation_repository.dart';

/// State cho form Chỉnh sửa Observation.
///
/// Khác với CreateObservationState (nhiều bước wizard), đây là 1 form
/// đơn — sửa dữ liệu có sẵn phù hợp với 1 màn cuộn dọc hơn là hướng
/// dẫn từng bước như lúc tạo mới (wizard hợp lý cho người mới bắt đầu
/// một hành động, không hợp cho việc chỉnh sửa nhanh dữ liệu đã có).
class EditObservationState {
  final List<String> existingPhotoUrls;
  final List<File> newPhotoFiles;
  final String title;
  final String description;
  final CategoryModel? category;
  final List<String> tags;
  final String rarity;
  final bool isSaving;
  final String? error;

  const EditObservationState({
    this.existingPhotoUrls = const [],
    this.newPhotoFiles = const [],
    this.title = '',
    this.description = '',
    this.category,
    this.tags = const [],
    this.rarity = ObservationRarity.common,
    this.isSaving = false,
    this.error,
  });

  factory EditObservationState.fromObservation(ObservationModel o) {
    return EditObservationState(
      existingPhotoUrls: o.photos,
      title: o.title,
      description: o.description ?? '',
      category: CategoryModel(
        id: o.categoryId,
        name: o.categoryName,
        icon: o.categoryIcon,
      ),
      tags: o.tags,
      rarity: o.rarity,
    );
  }

  int get totalPhotoCount => existingPhotoUrls.length + newPhotoFiles.length;

  bool get isValid =>
      title.trim().isNotEmpty &&
      category != null &&
      totalPhotoCount >= AppConstants.minPhotosPerObservation;

  EditObservationState copyWith({
    List<String>? existingPhotoUrls,
    List<File>? newPhotoFiles,
    String? title,
    String? description,
    CategoryModel? category,
    List<String>? tags,
    String? rarity,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return EditObservationState(
      existingPhotoUrls: existingPhotoUrls ?? this.existingPhotoUrls,
      newPhotoFiles: newPhotoFiles ?? this.newPhotoFiles,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rarity: rarity ?? this.rarity,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EditObservationViewModel extends StateNotifier<EditObservationState> {
  final Ref ref;
  final String observationId;

  EditObservationViewModel(this.ref, this.observationId, ObservationModel initial)
      : super(EditObservationState.fromObservation(initial));

  void removeExistingPhoto(int index) {
    final updated = [...state.existingPhotoUrls]..removeAt(index);
    state = state.copyWith(existingPhotoUrls: updated);
  }

  void removeNewPhoto(int index) {
    final updated = [...state.newPhotoFiles]..removeAt(index);
    state = state.copyWith(newPhotoFiles: updated);
  }

  void addPhotos(List<File> files) {
    final combined = [...state.newPhotoFiles, ...files];
    final maxNew =
        AppConstants.maxPhotosPerObservation - state.existingPhotoUrls.length;
    final capped = combined.length > maxNew ? combined.sublist(0, maxNew) : combined;
    state = state.copyWith(newPhotoFiles: capped);
  }

  void setTitle(String value) => state = state.copyWith(title: value);
  void setDescription(String value) => state = state.copyWith(description: value);
  void setCategory(CategoryModel category) =>
      state = state.copyWith(category: category);

  void addTag(String tag) {
    final normalized = tag.trim().toLowerCase().replaceAll(' ', '_');
    if (normalized.isEmpty || state.tags.contains(normalized)) return;
    state = state.copyWith(tags: [...state.tags, normalized]);
  }

  void removeTag(String tag) {
    state = state.copyWith(tags: state.tags.where((t) => t != tag).toList());
  }

  void setRarity(String rarity) => state = state.copyWith(rarity: rarity);

  Future<bool> save() async {
    if (!state.isValid) return false;

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repository = ref.read(observationRepositoryProvider);
      await repository.updateObservationDetails(
        id: observationId,
        existingPhotoUrls: state.existingPhotoUrls,
        newPhotoFiles: state.newPhotoFiles,
        title: state.title,
        description: state.description,
        category: state.category!,
        tags: state.tags,
        rarity: state.rarity,
      );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final editObservationViewModelProvider = StateNotifierProvider.autoDispose
    .family<EditObservationViewModel, EditObservationState, ObservationModel>(
        (ref, observation) {
  return EditObservationViewModel(ref, observation.id, observation);
});
