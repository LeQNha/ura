import 'package:geolocator/geolocator.dart';
import '../../observation/models/observation_model.dart';
import '../models/expedition_model.dart';

/// "What Did You Miss?" (tài liệu 12.3) — mức **Level 1: Nearby
/// Misses** (đơn giản nhất theo tài liệu đề xuất): tìm Observation nằm
/// trong bán kính gần BẤT KỲ điểm nào trên route đã đi, mà KHÔNG phải
/// do chính chuyến Expedition này tạo ra.
///
/// Chưa làm Level 2 (Route-aware — tính khoảng cách đến ĐOẠN đường,
/// không chỉ từng điểm rời rạc) hay Level 3 (Intelligent — ưu tiên
/// theo sở thích category/rarity của user) — đúng tinh thần "bắt đầu
/// từ phiên bản đơn giản" mà tài liệu khuyến nghị, có thể nâng cấp sau.
///
/// Đây là hàm thuần túy (pure function) — không phụ thuộc Firestore,
/// dễ kiểm tra logic độc lập với dữ liệu thật.
List<({ObservationModel observation, double distanceToRoute})>
    findMissedObservations({
  required ExpeditionModel expedition,
  required List<ObservationModel> candidates,
  double radiusMeters = 75,
  int maxResults = 5,
}) {
  if (expedition.routePoints.isEmpty) return [];

  final results = <({ObservationModel observation, double distanceToRoute})>[];

  for (final observation in candidates) {
    // Bỏ qua Observation đã tạo ngay trong chính chuyến đi này — đó là
    // thứ user ĐÃ tìm thấy, không phải "bỏ lỡ".
    if (observation.expeditionId == expedition.id) continue;

    double? nearestDistance;
    for (final point in expedition.routePoints) {
      final distance = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        observation.latitude,
        observation.longitude,
      );
      if (nearestDistance == null || distance < nearestDistance) {
        nearestDistance = distance;
      }
      // Đã đủ gần rồi thì không cần so tiếp các điểm route còn lại —
      // chỉ là tối ưu nhỏ, không ảnh hưởng kết quả.
      if (nearestDistance <= 1) break;
    }

    if (nearestDistance != null && nearestDistance <= radiusMeters) {
      results.add((observation: observation, distanceToRoute: nearestDistance));
    }
  }

  results.sort((a, b) => a.distanceToRoute.compareTo(b.distanceToRoute));
  return results.take(maxResults).toList();
}
