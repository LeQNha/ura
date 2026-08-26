import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Reverse geocoding (tọa độ → địa chỉ dạng chữ) qua Nominatim — dịch vụ
/// chính thức, miễn phí của OpenStreetMap. Đây là lựa chọn "0 đồng" đã
/// thống nhất, thay vì Google Geocoding API (cần thẻ tín dụng).
///
/// ⚠️ Nominatim giới hạn ~1 request/giây và YÊU CẦU đặt User-Agent riêng
/// (không dùng User-Agent mặc định của http client) — vi phạm policy có
/// thể bị họ chặn IP tạm thời. Method này chỉ nên gọi 1 lần/Observation
/// (lúc tạo mới), không gọi lặp lại nhiều lần.
///
/// Lỗi ở service này KHÔNG nên làm gián đoạn luồng tạo Observation —
/// address chỉ là thông tin "có thì tốt", nên mọi lỗi được nuốt và trả
/// về null thay vì throw.
class NominatimService {
  static const _userAgent = 'UrbanArchaeologyApp/1.0 (student thesis project)';

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
    );

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = data['display_name'] as String?;
      return displayName;
    } catch (_) {
      // Nuốt lỗi có chủ đích — xem docstring ở trên.
      return null;
    }
  }
}

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});
