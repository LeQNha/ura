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
/// - **iOS Simulator**: dùng `http://localhost:8000`.
/// - **Đã deploy server lên cloud**: dán URL https đầy đủ.
///
/// Toàn bộ tính năng AI được thiết kế để **hỏng êm** (fail gracefully):
/// nếu server không chạy hoặc mất mạng, app vẫn hoạt động bình thường.
/// Riêng việc lập lộ trình có bộ dự phòng chạy ngay trên máy (xem
/// `PersonalizedTripViewModel`), nên không bắt buộc phải có server.
///
/// 📌 Server AI mới (thư mục `ai_route_server/`) chỉ cung cấp endpoint
/// `/plan-route` (lập lộ trình cá nhân hóa). Các endpoint cũ
/// (`/check-duplicate`, `/interesting-areas`, `/recommend`) không còn,
/// nên các tính năng tương ứng sẽ nhận kết quả rỗng.
class AiConfig {
  AiConfig._();

  static const String baseUrl = 'http://192.168.1.11:8000';

  /// API key (tùy chọn). Để chuỗi rỗng nếu server không đặt biến môi
  /// trường `AI_API_KEY`. Nếu server có đặt thì điền cùng giá trị ở đây;
  /// app sẽ gửi kèm trong header `X-API-Key`.
  static const String apiKey = '';

  /// Ngưỡng độ tương đồng để coi 2 ảnh là trùng lặp (0..1).
  /// (Chỉ dùng cho tính năng kiểm tra trùng lặp của server cũ.)
  static const double duplicateThreshold = 0.88;

  /// Thời gian chờ tối đa cho mỗi request — đặt ngắn vì đây là tính
  /// năng phụ trợ, không nên bắt người dùng đợi lâu nếu server chậm.
  static const Duration timeout = Duration(seconds: 20);

  /// Thời gian chờ riêng cho việc lập lộ trình. Thuật toán chạy chỉ vài
  /// chục mili-giây, nên nếu quá ngưỡng này thì coi như server không
  /// khả dụng và chuyển sang bộ lập lộ trình dự phòng trên máy.
  static const Duration routeTimeout = Duration(seconds: 12);

  /// Bán kính lọc Observation lân cận khi kiểm tra trùng lặp.
  static const double duplicateSearchRadiusMeters = 300;

  /// Bật/tắt toàn bộ tính năng AI mà không cần xoá code — tiện khi
  /// demo ở nơi không chạy được server Python.
  static const bool enabled = true;
}
