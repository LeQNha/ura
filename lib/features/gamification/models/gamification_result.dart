import 'achievement_model.dart';

/// Kết quả trả về sau 1 lần cộng XP (tạo Observation / hoàn thành
/// Expedition) — UI dùng để quyết định có hiện popup "Lên cấp!" và/hoặc
/// "Mở khóa Achievement" hay không.
class GamificationResult {
  final int xp;
  final int level;
  final bool leveledUp;
  final List<AchievementModel> newlyUnlocked;

  const GamificationResult({
    required this.xp,
    required this.level,
    this.leveledUp = false,
    this.newlyUnlocked = const [],
  });
}
