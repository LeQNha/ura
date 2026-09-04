import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../gamification/models/gamification_result.dart';
import '../../gamification/repositories/gamification_repository.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';

class MissionRepository {
  final MissionService _missionService;
  final GamificationRepository _gamificationRepository;

  MissionRepository(this._missionService, this._gamificationRepository);

  Stream<List<MissionModel>> watchMissions() => _missionService.watchMissions();

  Stream<List<String>> watchCompletedMissionIds(String userId) =>
      _missionService.watchCompletedMissionIds(userId);

  /// Tính tiến độ hiện tại của [user] với [mission] — trả về giá trị
  /// cùng đơn vị với `mission.targetValue` (số Observation hoặc mét).
  Future<double> getProgress(UserModel user, MissionModel mission) async {
    switch (mission.type) {
      case MissionType.quantity:
        return user.observationCount.toDouble();
      case MissionType.distance:
        return user.totalDistanceMeters;
      case MissionType.category:
        if (mission.targetCategoryId == null) return 0;
        final count = await _missionService.countObservationsByCategory(
          user.id,
          mission.targetCategoryId!,
        );
        return count.toDouble();
      default:
        return 0;
    }
  }

  /// Nhận thưởng Mission — kiểm tra lại tiến độ (không tin tưởng hoàn
  /// toàn vào UI, phòng trường hợp state cũ) và chưa từng claim trước
  /// đó. Trả về null nếu không đủ điều kiện hoặc đã claim rồi.
  Future<GamificationResult?> claimMission(
    UserModel user,
    MissionModel mission,
  ) async {
    final alreadyCompleted =
        await _missionService.isMissionCompleted(user.id, mission.id);
    if (alreadyCompleted) return null;

    final progress = await getProgress(user, mission);
    if (progress < mission.targetValue) return null;

    await _missionService.markMissionCompleted(user.id, mission.id);
    return _gamificationRepository.awardBonusXp(user.id, mission.rewardXp);
  }
}

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository(
    ref.watch(missionServiceProvider),
    ref.watch(gamificationRepositoryProvider),
  );
});
