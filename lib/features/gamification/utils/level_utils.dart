import '../../../core/constants/app_constants.dart';

/// Các hàm tính Level/XP thuần túy — không phụ thuộc Firestore/Flutter,
/// dễ kiểm tra logic độc lập.
///
/// Đường cong Level: ngưỡng XP để đạt Level L = 50 × (L-1) × L — tăng
/// dần đều (100, 300, 600, 1000, 1500...) giống nhịp độ khó tăng dần
/// quen thuộc trong game, không cần công thức phức tạp hơn cho quy mô
/// đồ án.

int xpThresholdForLevel(int level) {
  if (level <= 1) return 0;
  return 50 * (level - 1) * level;
}

/// Tính Level hiện tại từ tổng XP. Dùng vòng lặp đơn giản (không phải
/// công thức nghịch đảo) để tránh sai số làm tròn — với quy mô XP của
/// 1 đồ án, vòng lặp này chỉ chạy vài chục lần là cùng, không đáng lo
/// hiệu năng.
int levelForXp(int xp) {
  var level = 1;
  while (level < 200 && xpThresholdForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
}

/// Tỉ lệ hoàn thành (0..1) từ Level hiện tại đến Level kế tiếp — dùng
/// vẽ progress bar.
double levelProgress(int xp, int level) {
  final current = xpThresholdForLevel(level);
  final next = xpThresholdForLevel(level + 1);
  if (next <= current) return 1;
  return ((xp - current) / (next - current)).clamp(0, 1).toDouble();
}

/// Xếp hạng độ hiếm thành số để so sánh (0=common .. 3=very_rare) —
/// dùng cho Achievement dạng "tìm được rarity X trở lên".
int rarityRank(String rarity) {
  switch (rarity) {
    case ObservationRarity.uncommon:
      return 1;
    case ObservationRarity.rare:
      return 2;
    case ObservationRarity.veryRare:
      return 3;
    case ObservationRarity.common:
    default:
      return 0;
  }
}
