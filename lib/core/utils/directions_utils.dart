import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mở "Chỉ đường" tới 1 tọa độ bằng app bản đồ có sẵn trên máy (Google
/// Maps trên Android, Apple/Google Maps trên iOS) qua URL chuẩn của
/// Google — không cần API key, không cần tự vẽ route trong app.
///
/// Đây là "Cách B" đã thống nhất (thay vì tự vẽ Polyline bằng OSRM
/// trong app): rời khỏi app 1 chút, đổi lại được chỉ đường thật, có
/// traffic thời gian thực, giọng đọc dẫn đường — thứ mà tự vẽ trong
/// app không có được. Nếu sau này muốn giữ user ở lại trong app, đây
/// là chỗ duy nhất cần thay đổi (đổi cách xử lý bên trong hàm này),
/// mọi nơi gọi hàm này không cần sửa gì.
///
/// [travelMode] mặc định là "walking" — đúng bản chất "đi bộ khám phá
/// đô thị" của app, khác với mặc định "driving" của Google Maps.
Future<void> openDirectionsTo(
  BuildContext context, {
  required double latitude,
  required double longitude,
  String travelMode = 'walking',
}) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$latitude,$longitude'
    '&travelmode=$travelMode',
  );

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ứng dụng bản đồ để mở.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở chỉ đường: $e')),
      );
    }
  }
}

/// Mở TOÀN BỘ lộ trình nhiều điểm dừng trên Google Maps cùng lúc —
/// dùng tham số `waypoints` của Google Maps URL API để nối các điểm
/// giữa thành 1 lộ trình có thứ tự, thay vì phải mở từng điểm rời rạc
/// nhiều lần. Dùng cho tính năng Trip Planning.
///
/// Google Maps giới hạn khoảng 9-10 waypoint cho kiểu URL này trên di
/// động — với tối đa 6 điểm dừng mặc định của `planTrip()`, không
/// chạm giới hạn này.
Future<void> openMultiStopDirections(
  BuildContext context, {
  required double originLat,
  required double originLng,
  required List<({double latitude, double longitude})> stops,
  String travelMode = 'walking',
}) async {
  if (stops.isEmpty) return;

  final destination = stops.last;
  final middleStops = stops.sublist(0, stops.length - 1);

  // Dùng Uri.https(...) với queryParameters thay vì tự nối chuỗi thủ
  // công — để Dart tự lo việc encode đúng các ký tự đặc biệt (dấu `|`
  // ngăn cách waypoint, dấu `,` trong tọa độ...), tránh URL bị sai.
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': '$originLat,$originLng',
    'destination': '${destination.latitude},${destination.longitude}',
    if (middleStops.isNotEmpty)
      'waypoints':
          middleStops.map((s) => '${s.latitude},${s.longitude}').join('|'),
    'travelmode': travelMode,
  });

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ứng dụng bản đồ để mở.')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở chỉ đường: $e')),
      );
    }
  }
}
