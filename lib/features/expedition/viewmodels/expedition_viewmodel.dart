import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/expedition_model.dart';
import '../repositories/expedition_repository.dart';

/// State cho action Start/End/Cancel — CHỈ chứa cờ loading/error, không
/// chứa dữ liệu route/distance hiển thị (những cái đó UI đọc trực tiếp
/// từ `activeExpeditionProvider`, vì mỗi lần ghi 1 điểm route lên
/// Firestore, listener realtime sẽ tự đẩy dữ liệu mới về UI — không
/// cần ViewModel giữ thêm 1 bản sao state để đồng bộ thủ công).
class ExpeditionActionState {
  final bool isStarting;
  final bool isEnding;
  final String? error;

  const ExpeditionActionState({
    this.isStarting = false,
    this.isEnding = false,
    this.error,
  });

  ExpeditionActionState copyWith({
    bool? isStarting,
    bool? isEnding,
    String? error,
    bool clearError = false,
  }) {
    return ExpeditionActionState(
      isStarting: isStarting ?? this.isStarting,
      isEnding: isEnding ?? this.isEnding,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel quản lý toàn bộ vòng đời GPS tracking của 1 Expedition.
///
/// KHÔNG dùng `autoDispose` — quan trọng: subscription theo dõi vị trí
/// (`_positionSubscription`) phải tiếp tục chạy kể cả khi user điều
/// hướng sang màn khác (vd bấm "Ghi nhận" để tạo Observation giữa
/// chừng chuyến đi) mà không bị hủy giữa chừng.
class ExpeditionViewModel extends StateNotifier<ExpeditionActionState> {
  final Ref ref;

  StreamSubscription<Position>? _positionSubscription;
  String? _activeExpeditionId;
  double _distanceMeters = 0;
  Position? _lastPosition;

  ExpeditionViewModel(this.ref) : super(const ExpeditionActionState());

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        error: 'Vui lòng bật GPS/Dịch vụ vị trí trên thiết bị.',
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        error: 'Bạn cần cấp quyền vị trí để bắt đầu Expedition.',
      );
      return false;
    }
    return true;
  }

  Future<void> start() async {
    state = state.copyWith(isStarting: true, clearError: true);

    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) {
      state = state.copyWith(isStarting: false);
      return;
    }

    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) {
      state = state.copyWith(
        isStarting: false,
        error: 'Không xác định được người dùng hiện tại.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final repository = ref.read(expeditionRepositoryProvider);
      final id = await repository.startExpedition(
        userId: currentUser.id,
        startPoint: RoutePoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        ),
      );

      _activeExpeditionId = id;
      _distanceMeters = 0;
      _lastPosition = position;

      _startPositionStream(id);

      state = state.copyWith(isStarting: false);
    } catch (e) {
      state = state.copyWith(isStarting: false, error: e.toString());
    }
  }

  /// Gắn lại GPS stream cho 1 Expedition đang active sẵn có trên
  /// Firestore — cần thiết khi app bị tắt/mở lại giữa chừng chuyến đi
  /// (subscription trong bộ nhớ bị mất, nhưng document Firestore với
  /// status 'active' vẫn còn, nên phải resume chứ không phải start mới).
  void resume(ExpeditionModel expedition) {
    if (_activeExpeditionId == expedition.id) return; // đã đang chạy rồi
    _activeExpeditionId = expedition.id;
    _distanceMeters = expedition.distanceMeters;
    _lastPosition = null; // điểm tiếp theo sẽ tính từ điểm cuối đã lưu
    if (expedition.routePoints.isNotEmpty) {
      final last = expedition.routePoints.last;
      _lastPosition = Position(
        latitude: last.latitude,
        longitude: last.longitude,
        timestamp: last.timestamp,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }
    _startPositionStream(expedition.id);
  }

  void _startPositionStream(String expeditionId) {
    _positionSubscription?.cancel();

    // distanceFilter: 15 — chỉ nhận vị trí mới khi đã di chuyển tối
    // thiểu 15m, thay vì cập nhật liên tục mỗi giây. Đây chính là cách
    // "throttle" đã thống nhất để tiết kiệm Firestore write quota và
    // pin thiết bị, mà vẫn đủ chi tiết cho 1 chuyến đi bộ khám phá.
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) => _onPositionUpdate(expeditionId, position));
  }

  Future<void> _onPositionUpdate(String expeditionId, Position position) async {
    if (_lastPosition != null) {
      final delta = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _distanceMeters += delta;
    }
    _lastPosition = position;

    final repository = ref.read(expeditionRepositoryProvider);
    try {
      await repository.appendRoutePoint(
        expeditionId,
        RoutePoint(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        ),
        _distanceMeters,
      );
    } catch (_) {
      // Không làm gián đoạn tracking chỉ vì 1 lần ghi Firestore lỗi
      // (vd mất mạng thoáng qua) — điểm tiếp theo sẽ tự thử lại.
    }
  }

  /// Kết thúc Expedition — trả về Expedition id để UI điều hướng sang
  /// Summary, hoặc null nếu có lỗi.
  Future<String?> end() async {
    if (_activeExpeditionId == null) return null;
    final id = _activeExpeditionId!;

    state = state.copyWith(isEnding: true, clearError: true);
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      final repository = ref.read(expeditionRepositoryProvider);
      await repository.completeExpedition(id, distanceMeters: _distanceMeters);
      _activeExpeditionId = null;
      _distanceMeters = 0;
      _lastPosition = null;
      state = state.copyWith(isEnding: false);
      return id;
    } catch (e) {
      state = state.copyWith(isEnding: false, error: e.toString());
      return null;
    }
  }

  Future<void> cancel() async {
    if (_activeExpeditionId == null) return;
    final id = _activeExpeditionId!;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final repository = ref.read(expeditionRepositoryProvider);
    await repository.cancelExpedition(id);

    _activeExpeditionId = null;
    _distanceMeters = 0;
    _lastPosition = null;
  }
}

final expeditionViewModelProvider =
    StateNotifierProvider<ExpeditionViewModel, ExpeditionActionState>((ref) {
  return ExpeditionViewModel(ref);
});

/// Expedition đang active của user hiện tại (null nếu không có).
/// Dùng ở nhiều nơi: Expedition tab, và Create Observation (để tự động
/// gắn Observation mới vào Expedition đang chạy nếu có).
final activeExpeditionProvider = StreamProvider<ExpeditionModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider).valueOrNull;
  if (currentUser == null) return Stream.value(null);
  final repository = ref.watch(expeditionRepositoryProvider);
  return repository.watchActiveExpedition(currentUser.id);
});

/// Expedition cụ thể theo id — dùng ở Summary page.
final expeditionDetailProvider =
    StreamProvider.family.autoDispose<ExpeditionModel?, String>((ref, id) {
  final repository = ref.watch(expeditionRepositoryProvider);
  return repository.watchExpedition(id);
});
