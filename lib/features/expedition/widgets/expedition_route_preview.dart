import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../models/expedition_model.dart';

/// Bản đồ mini vẽ lại đường đi (route) của 1 Expedition — dùng chung
/// cho màn theo dõi trực tiếp (đang thám hiểm) và Summary (sau khi kết
/// thúc). Tự tính center/zoom từ phạm vi các điểm route, không dùng
/// fitCamera/fitBounds của flutter_map để tránh phụ thuộc vào API có
/// thể khác nhau giữa các version.
class ExpeditionRoutePreview extends StatelessWidget {
  final List<RoutePoint> routePoints;
  final bool interactive;
  final double height;

  const ExpeditionRoutePreview({
    super.key,
    required this.routePoints,
    this.interactive = false,
    this.height = 220,
  });

  ({LatLng center, double zoom}) _computeCameraFit() {
    if (routePoints.isEmpty) {
      return (center: const LatLng(16.0471, 108.2062), zoom: 5);
    }
    if (routePoints.length == 1) {
      return (
        center: LatLng(routePoints.first.latitude, routePoints.first.longitude),
        zoom: 16,
      );
    }

    var minLat = routePoints.first.latitude;
    var maxLat = routePoints.first.latitude;
    var minLng = routePoints.first.longitude;
    var maxLng = routePoints.first.longitude;

    for (final p in routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final dLat = maxLat - minLat;
    final dLng = maxLng - minLng;
    final diagonal = (dLat * dLat + dLng * dLng);

    double zoom;
    if (diagonal < 0.00001) {
      zoom = 17;
    } else if (diagonal < 0.0001) {
      zoom = 15;
    } else if (diagonal < 0.001) {
      zoom = 14;
    } else if (diagonal < 0.01) {
      zoom = 12;
    } else if (diagonal < 0.1) {
      zoom = 10;
    } else {
      zoom = 7;
    }

    return (center: center, zoom: zoom);
  }

  @override
  Widget build(BuildContext context) {
    final fit = _computeCameraFit();
    final points = routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: routePoints.isEmpty
            ? Container(
                color: const Color(0xFFEDEAE3),
                alignment: Alignment.center,
                child: const Text('Chưa có dữ liệu vị trí'),
              )
            : FlutterMap(
                options: MapOptions(
                  initialCenter: fit.center,
                  initialZoom: fit.zoom,
                  interactionOptions: InteractionOptions(
                    flags: interactive
                        ? InteractiveFlag.all
                        : InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.urban_archaeology',
                  ),
                  if (points.length > 1)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: points,
                        strokeWidth: 4,
                        color: AppColors.primary,
                      ),
                    ]),
                  MarkerLayer(markers: [
                    Marker(
                      point: points.first,
                      width: 20,
                      height: 20,
                      child: const _RoutePin(color: AppColors.success),
                    ),
                    if (points.length > 1)
                      Marker(
                        point: points.last,
                        width: 20,
                        height: 20,
                        child: const _RoutePin(color: AppColors.error),
                      ),
                  ]),
                ],
              ),
      ),
    );
  }
}

class _RoutePin extends StatelessWidget {
  final Color color;

  const _RoutePin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
