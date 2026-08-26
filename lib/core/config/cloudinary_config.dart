/// Cấu hình Cloudinary.
///
/// ⚠️ BẠN CẦN ĐIỀN 2 GIÁ TRỊ NÀY trước khi chạy tính năng upload ảnh.
/// Xem hướng dẫn lấy 2 giá trị này trong README_PHASE1.md, mục "Setup
/// Cloudinary". Cả hai đều lấy free, không cần thẻ tín dụng.
///
/// Lý do dùng "Unsigned Upload Preset" thay vì API Key/Secret: app di
/// động không nên nhúng API Secret trong code (dễ bị người khác trích
/// xuất ngược và lợi dụng). Unsigned upload preset cho phép app upload
/// thẳng lên Cloudinary mà không cần secret, đổi lại ta giới hạn preset
/// đó (chỉ cho phép upload vào 1 folder, giới hạn kích thước ảnh) ngay
/// trên Cloudinary Dashboard để tránh bị lạm dụng.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'ds69hev5p';
  static const String uploadPreset = 'uraapp';

  static bool get isConfigured =>
      cloudName != 'YOUR_CLOUD_NAME' && uploadPreset != 'YOUR_UPLOAD_PRESET';
}
