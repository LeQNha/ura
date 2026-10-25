import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Hiển thị nhãn Hoàng Sa và Trường Sa như nhãn địa lý trên bản đồ.
///
/// Mỗi nhãn gắn với một tọa độ LatLng, không phải tọa độ pixel của màn hình.
/// Vì vậy nhãn tự di chuyển theo bản đồ và giữ nguyên vị trí địa lý khi kéo,
/// phóng to hoặc thu nhỏ. Kích thước chữ thay đổi nhẹ theo mức zoom.
class IslandLabelsLayer extends StatelessWidget {
  const IslandLabelsLayer({super.key, required this.zoom});

  final double zoom;

  // Tọa độ đại diện gần trung tâm khu vực của mỗi quần đảo.
  // Đây là điểm đặt nhãn trên bản đồ, không phải tọa độ của một đảo riêng lẻ.
  static const LatLng _hoangSaLabelPoint = LatLng(16.5, 112.0);
  static const LatLng _truongSaLabelPoint = LatLng(9.5, 114.0);

  double get _fontSize =>
      (11.0 + (zoom - 5.0) * 0.55).clamp(10.0, 18.0).toDouble();

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        Marker(
          point: _hoangSaLabelPoint,
          width: 116,
          height: 32,
          alignment: Alignment.center,
          child: _IslandLabel(text: 'Hoàng Sa', fontSize: _fontSize),
        ),
        Marker(
          point: _truongSaLabelPoint,
          width: 116,
          height: 32,
          alignment: Alignment.center,
          child: _IslandLabel(text: 'Trường Sa', fontSize: _fontSize),
        ),
      ],
    );
  }
}

class _IslandLabel extends StatelessWidget {
  const _IslandLabel({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Không chặn thao tác kéo/zoom bản đồ bên dưới nhãn.
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xCC123B55),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withOpacity(0.82),
              width: 0.7,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}
