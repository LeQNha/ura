import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Bảng màu của Urban Archaeology.
///
/// Concept "Modern Urban Explorer + Field Research Journal":
/// - Primary: Amber/Orange — discovery, urban, old photographs.
/// - Accent: xanh rêu đậm — thiên nhiên "chiếm lại" không gian đô thị cũ,
///   tương phản ấm/lạnh có chủ đích với Amber.
///
/// ⚠️ Mọi member cũ được GIỮ NGUYÊN tên + giá trị; chỉ BỔ SUNG token mới
/// (ink, accentGradient, scrim, cardShadow...) để không ảnh hưởng các màn
/// đang tham chiếu.
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFFE8890C);
  static const Color primaryDark = Color(0xFFB86A00);
  static const Color primaryLight = Color(0xFFFFB74D);

  // Neutral - Light
  static const Color backgroundLight = Color(0xFFFAF9F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1C1B1A);
  static const Color textSecondaryLight = Color(0xFF6B6864);

  // Neutral - Dark
  static const Color backgroundDark = Color(0xFF1A1918);
  static const Color surfaceDark = Color(0xFF242322);
  static const Color textPrimaryDark = Color(0xFFF5F3F0);
  static const Color textSecondaryDark = Color(0xFFA8A5A0);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Rarity
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

  // Accent
  static const Color accent = Color(0xFF1F6F5C);
  static const Color accentDark = Color(0xFF124A3D);
  static const Color accentLight = Color(0xFF4F9C87);

  static const Color borderLight = Color(0xFFE5E2DC);
  static const Color borderDark = Color(0xFF34322F);

  static const Color surfaceMutedLight = Color(0xFFF3F0EA);
  static const Color surfaceMutedDark = Color(0xFF2C2B29);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0993D), primary, primaryDark],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

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

  // ---------------------------------------------------------------
  // MỚI (đợt nâng cấp giao diện lần 2) — chỉ bổ sung
  // ---------------------------------------------------------------

  /// Màu "mực" rất đậm — dùng cho chữ/ nền tối sang trọng trên ảnh.
  static const Color ink = Color(0xFF14110F);

  /// Gradient rêu — cặp đôi với [primaryGradient] cho khối phụ.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent, accentDark],
    stops: [0, 0.5, 1],
  );

  /// Lớp phủ tối dần từ trên xuống — giúp nút/chữ trắng luôn đọc được
  /// khi nằm trên ảnh bất kỳ.
  static const LinearGradient topScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x99000000), Colors.transparent],
  );

  static const LinearGradient bottomScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC000000)],
  );

  /// Bóng đổ chuẩn cho card — nhẹ ở light, sâu hơn ở dark.
  static List<BoxShadow> cardShadow({required bool isDark}) {
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.38)
            : const Color(0xFF3A2A12).withOpacity(0.07),
        blurRadius: 22,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static Color surfaceOf(Brightness b) =>
      b == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceMutedOf(Brightness b) =>
      b == Brightness.dark ? surfaceMutedDark : surfaceMutedLight;

  static Color borderOf(Brightness b) =>
      b == Brightness.dark ? borderDark : borderLight;

  static Color textSecondaryOf(Brightness b) =>
      b == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  /// Màu chữ nhấn (amber) đủ tương phản theo từng chế độ sáng/tối.
  static Color primaryTextOf(Brightness b) =>
      b == Brightness.dark ? primaryLight : primaryDark;
}
