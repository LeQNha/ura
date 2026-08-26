import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Bảng màu của Urban Archaeology.
///
/// Theo concept "Modern Urban Explorer + Field Research Journal":
/// - Primary: Amber/Orange — gợi cảm giác discovery, warning, urban, old photographs.
/// - Background: off-white (light) / charcoal (dark).
///
/// Đặt hết màu vào một chỗ để dễ đổi theme sau này mà không phải sửa rải rác
/// khắp các file UI.
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
}
