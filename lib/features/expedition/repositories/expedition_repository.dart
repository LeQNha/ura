import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expedition_model.dart';
import '../services/expedition_service.dart';

class ExpeditionRepository {
  final ExpeditionService _service;

  ExpeditionRepository(this._service);

  /// Bắt đầu Expedition mới.
  Future<String> startExpedition({
    required String userId,
    required RoutePoint startPoint,
  }) async {
    final expedition = ExpeditionModel(
      id: '',
      userId: userId,
      startedAt: DateTime.now(),
      status: ExpeditionStatus.active,
      routePoints: [startPoint],
      distanceMeters: 0,
      observationCount: 0,
    );
    return _service.createExpedition(expedition);
  }

  Stream<ExpeditionModel?> watchActiveExpedition(String userId) =>
      _service.watchActiveExpedition(userId);

  Stream<ExpeditionModel?> watchExpedition(String id) =>
      _service.watchExpedition(id);

  Future<void> appendRoutePoint(
    String expeditionId,
    RoutePoint point,
    double totalDistanceMeters,
  ) =>
      _service.appendRoutePoint(expeditionId, point, totalDistanceMeters);

  Future<void> completeExpedition(
    String id, {
    required double distanceMeters,
  }) =>
      _service.completeExpedition(
        id,
        endedAt: DateTime.now(),
        distanceMeters: distanceMeters,
      );

  Future<void> cancelExpedition(String id) => _service.cancelExpedition(id);

  Future<void> incrementObservationCount(String id) async {
    try {
      await _service.incrementObservationCount(id);
    } catch (e) {
      // Không throw ra ngoài — đây là thao tác "tiện thì tốt" đi kèm
      // sau khi Observation đã tạo thành công; lỗi ở đây không nên làm
      // luồng Create Observation (vốn đã thành công) báo lỗi ngược lại.
      // ignore: avoid_print
      print('Lỗi cập nhật observationCount cho Expedition: $e');
    }
  }
}

final expeditionRepositoryProvider = Provider<ExpeditionRepository>((ref) {
  final service = ref.watch(expeditionServiceProvider);
  return ExpeditionRepository(service);
});
