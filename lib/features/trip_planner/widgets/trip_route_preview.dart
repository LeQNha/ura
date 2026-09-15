import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../models/trip_plan.dart';

/// Bản đồ mini vẽ lại lộ trình đã lập kế hoạch — điểm xuất phát (icon
/// người), các điểm dừng đánh số theo thứ tự, và đường nối khép kín
/// quay về điểm xuất phát.
///
/// Tự tính center/zoom từ phạm vi các điểm (không dùng fitCamera của
/// flutter_map để tránh phụ thuộc API có thể khác nhau giữa các
/// version — cùng cách làm đã dùng ở các bản đồ mini khác trong app).
class TripRoutePreview extends StatelessWidget {
  final LatLng start;
  final TripPlan plan;
  final double height;

  const TripRoutePreview({
    super.key,
    required this.start,
    required this.plan,
    this.height = 240,
  });

  ({LatLng center, double zoom}) _computeCameraFit() {
    final points = [start, ...plan.stops.map((s) => LatLng(
          s.observation.latitude,
          s.observation.longitude,
        ))];

    if (points.length == 1) return (center: points.first, zoom: 15);

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final dLat = maxLat - minLat;
    final dLng = maxLng - minLng;
    final diagonal = dLat * dLat + dLng * dLng;

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
    final stopPoints = plan.stops
        .map((s) => LatLng(s.observation.latitude, s.observation.longitude))
        .toList();
    final loopPoints = [start, ...stopPoints, start];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: fit.center,
            initialZoom: fit.zoom,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.urban_archaeology',
            ),
            if (loopPoints.length > 1)
              PolylineLayer(polylines: [
                Polyline(
                  points: loopPoints,
                  strokeWidth: 4,
                  color: AppColors.primary,
                ),
              ]),
            MarkerLayer(markers: [
              Marker(
                point: start,
                width: 30,
                height: 30,
                child: const _StartMarker(),
              ),
              for (var i = 0; i < stopPoints.length; i++)
                Marker(
                  point: stopPoints[i],
                  width: 28,
                  height: 28,
                  child: _NumberedMarker(number: i + 1),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _StartMarker extends StatelessWidget {
  const _StartMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.info,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 16, color: Colors.white),
    );
  }
}

class _NumberedMarker extends StatelessWidget {
  final int number;

  const _NumberedMarker({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
