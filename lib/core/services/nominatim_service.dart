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
/// Kết quả trả về từ Nominatim `/search` (forward geocoding) — 1 địa
/// điểm khớp với chuỗi tìm kiếm của user.
class NominatimPlace {
  final String displayName;
  final double latitude;
  final double longitude;

  const NominatimPlace({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

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
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = data['display_name'] as String?;
      return displayName;
    } catch (_) {
      // Nuốt lỗi có chủ đích — xem docstring ở trên.
      return null;
    }
  }

  /// Forward geocoding (chuỗi tìm kiếm → danh sách địa điểm khớp) — dùng
  /// cho tính năng "Tìm địa điểm" trên Map. Khác với [reverseGeocode]
  /// (chỉ gọi 1 lần/Observation), hàm này gọi theo mỗi lần user gõ tìm
  /// kiếm — nơi gọi hàm này BẮT BUỘC phải tự debounce (đợi user ngừng
  /// gõ một lúc mới gọi), không được gọi trực tiếp theo từng ký tự, để
  /// tôn trọng giới hạn ~1 request/giây của Nominatim.
  Future<List<NominatimPlace>> search(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?format=json&q=${Uri.encodeQueryComponent(query.trim())}&limit=$limit',
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': _userAgent
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        return NominatimPlace(
          displayName: map['display_name'] as String? ?? '',
          latitude: double.tryParse(map['lat'] as String? ?? '') ?? 0,
          longitude: double.tryParse(map['lon'] as String? ?? '') ?? 0,
        );
      }).toList();
    } catch (_) {
      // Nuốt lỗi có chủ đích — nếu tìm địa điểm lỗi, chỉ hiện danh sách
      // rỗng, không nên làm gián đoạn cả màn Map.
      return [];
    }
  }
}

final nominatimServiceProvider = Provider<NominatimService>((ref) {
  return NominatimService();
});
