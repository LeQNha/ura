import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index của tab đang được chọn trong `HomeShellPage`.
///
/// Đặt ở core/ (không đặt trong home_shell_page.dart) để tránh feature
/// khác (vd Scanner cần biết mình có đang là tab đang hiển thị không,
/// để tạm dừng camera khi không active) phải import ngược vào feature
/// home — như vậy cả 2 phía chỉ phụ thuộc vào core, không phụ thuộc
/// lẫn nhau.
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);
