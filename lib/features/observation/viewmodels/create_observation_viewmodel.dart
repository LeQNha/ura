import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/nominatim_service.dart';
import '../../auth/models/user_model.dart';
import '../../expedition/viewmodels/expedition_viewmodel.dart';
import '../models/category_model.dart';
import '../repositories/observation_repository.dart';
import '../../expedition/repositories/expedition_repository.dart';

/// State cho toàn bộ luồng Create Observation (nhiều bước: Photos →
/// Location → Info → Review). Gom hết vào 1 state class thay vì tách
/// nhiều Provider nhỏ, vì các field này liên quan chặt với nhau và
/// luôn được submit cùng lúc — tách nhỏ chỉ khiến việc đồng bộ phức tạp
/// hơn mà không có lợi ích gì.
class CreateObservationState {
  final int currentStep;

  final List<File> photos;

  final double? latitude;
  final double? longitude;
  final String? address;
  final bool isLocating;
  final String? locationError;

  final String title;
  final String description;
  final CategoryModel? category;
  final List<String> tags;
  final String rarity;
  final DateTime observedAt;

  final bool isSubmitting;
  final String? submitError;

  const CreateObservationState({
    this.currentStep = 0,
    this.photos = const [],
    this.latitude,
    this.longitude,
    this.address,
    this.isLocating = false,
    this.locationError,
    this.title = '',
    this.description = '',
    this.category,
    this.tags = const [],
    this.rarity = ObservationRarity.common,
    required this.observedAt,
    this.isSubmitting = false,
    this.submitError,
  });

  factory CreateObservationState.initial() {
    return CreateObservationState(observedAt: DateTime.now());
  }

  bool get hasLocation => latitude != null && longitude != null;

  bool get isPhotosStepValid =>
      photos.length >= AppConstants.minPhotosPerObservation;

  bool get isLocationStepValid => hasLocation;

  bool get isInfoStepValid => title.trim().isNotEmpty && category != null;

  bool get canSubmit =>
      isPhotosStepValid && isLocationStepValid && isInfoStepValid;

  CreateObservationState copyWith({
    int? currentStep,
    List<File>? photos,
    double? latitude,
    double? longitude,
    String? address,
    bool? isLocating,
    String? locationError,
    bool clearLocationError = false,
    String? title,
    String? description,
    CategoryModel? category,
    List<String>? tags,
    String? rarity,
    DateTime? observedAt,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return CreateObservationState(
      currentStep: currentStep ?? this.currentStep,
      photos: photos ?? this.photos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isLocating: isLocating ?? this.isLocating,
      locationError:
          clearLocationError ? null : (locationError ?? this.locationError),
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rarity: rarity ?? this.rarity,
      observedAt: observedAt ?? this.observedAt,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

class CreateObservationViewModel extends StateNotifier<CreateObservationState> {
  final Ref ref;

  CreateObservationViewModel(this.ref)
      : super(CreateObservationState.initial());

  // ---- Step navigation ----

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  // ---- Photos ----

  void addPhotos(List<File> newPhotos) {
    final combined = [...state.photos, ...newPhotos];
    final capped = combined.length > AppConstants.maxPhotosPerObservation
        ? combined.sublist(0, AppConstants.maxPhotosPerObservation)
        : combined;
    state = state.copyWith(photos: capped);
  }

  void removePhotoAt(int index) {
    final updated = [...state.photos]..removeAt(index);
    state = state.copyWith(photos: updated);
  }

  // ---- Location ----

  /// Lấy vị trí GPS hiện tại + reverse geocode ra địa chỉ (best-effort).
  ///
  /// Xử lý đầy đủ các case permission theo tài liệu Geolocator: service
  /// tắt, permission denied, permission denied vĩnh viễn — mỗi case một
  /// message rõ ràng để user biết chính xác cần làm gì tiếp theo.
  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLocating: true, clearLocationError: true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Vui lòng bật GPS/Dịch vụ vị trí trên thiết bị.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Bạn cần cấp quyền vị trí để tạo Observation.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Quyền vị trí đã bị từ chối vĩnh viễn. '
            'Vào Cài đặt thiết bị để bật lại quyền cho app.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        isLocating: false,
      );

      // Reverse geocode không chặn luồng chính — nếu lỗi/chậm, user vẫn
      // có thể tiếp tục với lat/lng, không cần chờ có address.
      final nominatim = ref.read(nominatimServiceProvider);
      final address = await nominatim.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (address != null && mounted) {
        state = state.copyWith(address: address);
      }
    } catch (e) {
      state = state.copyWith(
        isLocating: false,
        locationError: e.toString(),
      );
    }
  }

  // ---- Info ----

  void setTitle(String value) => state = state.copyWith(title: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

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

  void setObservedAt(DateTime dateTime) =>
      state = state.copyWith(observedAt: dateTime);

  // ---- Submit ----

  /// Trả về observationId nếu thành công, null nếu thất bại (chi tiết
  /// lỗi nằm trong state.submitError để UI hiển thị).
  Future<String?> submit(UserModel creator) async {
    if (!state.canSubmit) return null;

    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    try {
      final repository = ref.read(observationRepositoryProvider);

      // Nếu đang có 1 Expedition active, tự động gắn Observation mới
      // vào chuyến đó — user không cần làm gì thêm, đúng tinh thần
      // "ghi nhận trong lúc thám hiểm" của core loop app.
      final activeExpedition = ref.read(activeExpeditionProvider).valueOrNull;

      final id = await repository.createObservation(
        creator: creator,
        photoFiles: state.photos,
        title: state.title,
        description: state.description,
        category: state.category!,
        tags: state.tags,
        latitude: state.latitude!,
        longitude: state.longitude!,
        address: state.address,
        observedAt: state.observedAt,
        rarity: state.rarity,
        expeditionId: activeExpedition?.id,
      );

      if (activeExpedition != null) {
        await ref
            .read(expeditionRepositoryProvider)
            .incrementObservationCount(activeExpedition.id);
      }

      state = state.copyWith(isSubmitting: false);
      return id;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.toString());
      return null;
    }
  }
}

/// autoDispose: state của form Create chỉ nên tồn tại trong lúc user
/// đang ở màn hình đó — rời màn hình (hủy hoặc submit xong) thì state
/// cũ phải mất đi, tránh lần tạo Observation tiếp theo bị dính dữ liệu
/// cũ (vd ảnh của lần tạo trước còn sót lại).
final createObservationViewModelProvider = StateNotifierProvider.autoDispose<
    CreateObservationViewModel, CreateObservationState>((ref) {
  return CreateObservationViewModel(ref);
});
