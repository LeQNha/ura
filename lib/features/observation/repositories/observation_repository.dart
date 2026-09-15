import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../auth/models/user_model.dart';
import '../models/category_model.dart';
import '../models/observation_model.dart';
import '../services/observation_service.dart';

/// ObservationRepository — "Tôi muốn tạo một Observation mới."
///
/// Phối hợp CloudinaryService (upload ảnh) + ObservationService (ghi
/// Firestore). ViewModel gọi vào đây, không cần biết ảnh được upload
/// lên đâu hay document được ghi vào collection nào.
class ObservationRepository {
  final ObservationService _observationService;
  final CloudinaryService _cloudinaryService;

  ObservationRepository(this._observationService, this._cloudinaryService);

  /// Tạo Observation mới — luồng đầy đủ: upload toàn bộ ảnh lên
  /// Cloudinary trước, có URL rồi mới ghi document Firestore. Làm theo
  /// thứ tự này để tránh trường hợp document có sẵn nhưng field `photos`
  /// rỗng nếu upload ảnh thất bại giữa chừng.
  Future<String> createObservation({
    required UserModel creator,
    required List<File> photoFiles,
    required String title,
    String? description,
    required CategoryModel category,
    required List<String> tags,
    required double latitude,
    required double longitude,
    String? address,
    required DateTime observedAt,
    required String rarity,
    String? expeditionId,
    void Function(int uploaded, int total)? onUploadProgress,
  }) async {
    final photoUrls = await _cloudinaryService.uploadImages(
      photoFiles,
      folder: 'observations',
      onProgress: onUploadProgress,
    );

    final now = DateTime.now();
    final observation = ObservationModel(
      id: '', // Firestore tự sinh id khi add()
      creatorId: creator.id,
      creatorUsername: creator.username,
      creatorAvatarUrl: creator.avatarUrl,
      title: title.trim(),
      description:
          (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      photos: photoUrls,
      categoryId: category.id,
      categoryName: category.name,
      categoryIcon: category.icon,
      tags: tags,
      latitude: latitude,
      longitude: longitude,
      address: address,
      observedAt: observedAt,
      createdAt: now,
      updatedAt: now,
      rarity: rarity,
      status: ObservationStatus.active,
      expeditionId: expeditionId,
    );

    return _observationService.createObservation(observation);
  }

  Future<ObservationModel?> getObservation(String id) =>
      _observationService.getObservation(id);

  Stream<ObservationModel?> watchObservation(String id) =>
      _observationService.watchObservation(id);

  Stream<List<ObservationModel>> watchLatestFeed({int limit = 30}) =>
      _observationService.watchLatestFeed(limit: limit);

  Stream<List<ObservationModel>> watchObservationsByCreator(String creatorId) =>
      _observationService.watchObservationsByCreator(creatorId);

  Future<void> softDeleteObservation(String id) =>
      _observationService.softDeleteObservation(id);

  /// Cập nhật 1 Observation đã tồn tại — dùng cho luồng "Chỉnh sửa"
  /// (Phase 8 bổ sung). Cho phép đổi cả ảnh: [newPhotoFiles] là ảnh mới
  /// chọn thêm (chưa upload), [existingPhotoUrls] là URL ảnh cũ user
  /// muốn GIỮ LẠI (ảnh nào bị xóa thì không có trong list này nữa — xử
  /// lý loại bỏ đã làm ở tầng UI/ViewModel trước khi gọi hàm này).
  /// Vị trí (lat/lng/address) KHÔNG được sửa qua hàm này — theo đúng
  /// quyết định giữ nguyên định vị gốc, tránh Observation "trôi" khỏi
  /// đúng vị trí thực tế đã ghi nhận ban đầu.
  Future<void> updateObservationDetails({
    required String id,
    required List<String> existingPhotoUrls,
    required List<File> newPhotoFiles,
    required String title,
    String? description,
    required CategoryModel category,
    required List<String> tags,
    required String rarity,
  }) async {
    final uploadedUrls = newPhotoFiles.isEmpty
        ? <String>[]
        : await _cloudinaryService.uploadImages(
            newPhotoFiles,
            folder: 'observations',
          );

    final photos = [...existingPhotoUrls, ...uploadedUrls];

    await _observationService.updateObservation(id, {
      'title': title.trim(),
      'description':
          (description?.trim().isEmpty ?? true) ? null : description!.trim(),
      'photos': photos,
      'categoryId': category.id,
      'categoryName': category.name,
      'categoryIcon': category.icon,
      'tags': tags,
      'rarity': rarity,
    });
  }
}

final observationRepositoryProvider = Provider<ObservationRepository>((ref) {
  final observationService = ref.watch(observationServiceProvider);
  final cloudinaryService = ref.watch(cloudinaryServiceProvider);
  return ObservationRepository(observationService, cloudinaryService);
});
