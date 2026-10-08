/// Cấu hình kết nối tới AI Backend (server Python chạy riêng).
///
/// ⚠️ BẠN CẦN SỬA [baseUrl] cho đúng máy của mình trước khi test.
///
/// Cách điền tuỳ môi trường chạy:
/// - **Máy Android thật, cùng Wi-Fi với laptop**: dùng địa chỉ IP nội
///   bộ của laptop, ví dụ `http://192.168.1.15:8000`. Xem IP bằng
///   lệnh `ipconfig` (Windows) hoặc `ifconfig` (macOS/Linux).
/// - **Máy ảo Android (emulator)**: dùng `http://10.0.2.2:8000` —
///   đây là địa chỉ đặc biệt trỏ về `localhost` của máy chủ, vì bên
///   trong emulator thì `localhost` là chính nó chứ không phải laptop.
/// - **Đã deploy server lên cloud**: dán URL https đầy đủ.
///
/// Toàn bộ tính năng AI được thiết kế để **hỏng êm** (fail gracefully):
/// nếu server không chạy hoặc mất mạng, app vẫn hoạt động bình thường,
/// chỉ là không có gợi ý / không cảnh báo trùng lặp. Không có tính năng
/// cốt lõi nào phụ thuộc bắt buộc vào server này.
class AiConfig {
  AiConfig._();

  static const String baseUrl = 'http://192.168.1.11:8000';

  /// Ngưỡng độ tương đồng để coi 2 ảnh là trùng lặp (0..1).
  /// Cao hơn = ít cảnh báo nhầm hơn nhưng dễ bỏ sót.
  static const double duplicateThreshold = 0.88;

  /// Thời gian chờ tối đa cho mỗi request — đặt ngắn vì đây là tính
  /// năng phụ trợ, không nên bắt người dùng đợi lâu nếu server chậm.
  static const Duration timeout = Duration(seconds: 20);

  /// Bán kính lọc Observation lân cận khi kiểm tra trùng lặp.
  static const double duplicateSearchRadiusMeters = 300;

  /// Bật/tắt toàn bộ tính năng AI mà không cần xoá code — tiện khi
  /// demo ở nơi không chạy được server Python.
  static const bool enabled = true;
}
