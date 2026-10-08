import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Bảng màu của Urban Archaeology.
///
/// Theo concept "Modern Urban Explorer + Field Research Journal":
/// - Primary: Amber/Orange — gợi cảm giác discovery, warning, urban, old photographs.
/// - Background: off-white (light) / charcoal (dark).
/// - Accent: xanh rêu đậm — gợi thiên nhiên "chiếm lại" không gian đô
///   thị cũ, tương phản ấm/lạnh có chủ đích với Amber (không phải màu
///   trang trí ngẫu nhiên).
///
/// Đặt hết màu vào một chỗ để dễ đổi theme sau này mà không phải sửa rải rác
/// khắp các file UI.
///
/// ⚠️ TOÀN BỘ member đã có từ trước (từ Phase 0) được GIỮ NGUYÊN tên +
/// giá trị — chỉ BỔ SUNG thêm token mới cho đợt nâng cấp giao diện,
/// không xóa/đổi gì để tránh ảnh hưởng các màn hình khác đang tham
/// chiếu tới các hằng số này.
class AppColors {
  AppColors._();

  // Primary — dùng cho: Discovery, Button, Marker, XP, Highlight
  static const Color primary = Color(0xFFE8890C); // Amber/Orange
  static const Color primaryDark = Color(0xFFB86A00);
  static const Color primaryLight = Color(0xFFFFB74D);

  // Neutral - Light mode
  static const Color backgroundLight = Color(0xFFFAF9F6); // off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1C1B1A);
  static const Color textSecondaryLight = Color(0xFF6B6864);

  // Neutral - Dark mode
  static const Color backgroundDark = Color(0xFF1A1918); // dark charcoal
  static const Color surfaceDark = Color(0xFF242322);
  static const Color textPrimaryDark = Color(0xFFF5F3F0);
  static const Color textSecondaryDark = Color(0xFFA8A5A0);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Rarity (dùng cho RarityBadge và Map Marker — cùng 1 nguồn màu để
  // luôn nhất quán giữa Card/Detail và Bản đồ)
  static const Color rarityCommon = Color(0xFF9E9E9E);
  static const Color rarityUncommon = Color(0xFF4CAF50);
  static const Color rarityRare = Color(0xFF2196F3);
  static const Color rarityLegendary = Color(0xFFE8890C);

  static Color rarityColor(String rarity) {
    switch (rarity) {
      case ObservationRarity.uncommon:
        return rarityUncommon;
      case ObservationRarity.rare:
        return rarityRare;
      case ObservationRarity.veryRare:
        return rarityLegendary;
      case ObservationRarity.common:
      default:
        return rarityCommon;
    }
  }

  // ---------------------------------------------------------------
  // MỚI (đợt nâng cấp giao diện) — bổ sung thêm, không đụng phần trên
  // ---------------------------------------------------------------

  /// Xanh rêu đậm — accent phụ, tương phản ấm/lạnh có chủ đích với
  /// Amber. Dùng cho các điểm nhấn phụ (không phải CTA chính): số liệu
  /// nổi bật, viền ring của badge đặc biệt, gradient hero thứ 2.
  static const Color accent = Color(0xFF1F6F5C);
  static const Color accentDark = Color(0xFF124A3D);
  static const Color accentLight = Color(0xFF4F9C87);

  /// Viền/chia tách — tách thành hằng số có tên thay vì hex rời rạc lặp
  /// lại nhiều nơi trong code (trước đây là `Color(0xFFE5E2DC)`/
  /// `Color(0xFF34322F)` gõ tay ở app_theme.dart).
  static const Color borderLight = Color(0xFFE5E2DC);
  static const Color borderDark = Color(0xFF34322F);

  /// Bề mặt "trầm" hơn surface chính — dùng cho khối nền phụ (chip nền,
  /// khối thông tin phụ) cần tách lớp nhẹ khỏi surface chính mà không
  /// cần tới border.
  static const Color surfaceMutedLight = Color(0xFFF3F0EA);
  static const Color surfaceMutedDark = Color(0xFF2C2B29);

  /// Gradient CTA chính — dùng cho nút/khối hành động quan trọng nhất
  /// trên mỗi màn (nút Đăng nhập, nút Đăng, FAB chính...). Thay flat
  /// color bằng gradient tinh tế tạo chiều sâu, KHÔNG dùng tràn lan
  /// (chỉ 1-2 chỗ nổi bật nhất mỗi màn, đúng nguyên tắc "spend boldness
  /// in one place").
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0993D), primary, primaryDark],
    stops: [0, 0.55, 1],
  );

  /// Gradient "khoảnh khắc đặc biệt" (Level Up, Achievement, Trip
  /// hoàn thành...) — phối Amber→Rêu, chỉ dùng cho popup ăn mừng, KHÔNG
  /// dùng làm nền thường xuyên.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  /// Bóng đổ có sắc ấm (dựa trên [tint], mặc định primary) thay vì đen
  /// thuần túy — tạo cảm giác "được nhuộm màu thương hiệu" thay vì
  /// bóng xám chung chung mà hầu như app nào cũng dùng.
  static List<BoxShadow> softShadow({
    Color tint = primary,
    double opacity = 0.16,
    double blur = 24,
    Offset offset = const Offset(0, 10),
  }) {
    return [
      BoxShadow(
        color: tint.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  /// Bóng đổ trung tính (đen, nhẹ) — dùng khi cần độ tương phản rõ hơn
  /// softShadow (vd marker/nút nổi trên nền ảnh/bản đồ đa dạng màu).
  static List<BoxShadow> neutralShadow({
    double opacity = 0.18,
    double blur = 16,
    Offset offset = const Offset(0, 6),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }
}
