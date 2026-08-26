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

  Future<List<ObservationModel>> getObservationsForExpedition(
    String expeditionId,
  ) =>
      _observationService.getObservationsForExpedition(expeditionId);

  Future<void> softDeleteObservation(String id) =>
      _observationService.softDeleteObservation(id);
}

final observationRepositoryProvider = Provider<ObservationRepository>((ref) {
  final observationService = ref.watch(observationServiceProvider);
  final cloudinaryService = ref.watch(cloudinaryServiceProvider);
  return ObservationRepository(observationService, cloudinaryService);
});
