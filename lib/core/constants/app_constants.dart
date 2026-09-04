/// Các hằng số dùng chung toàn app.
///
/// Tên collection Firestore được đặt tập trung ở đây để nếu sau này
/// cần đổi tên collection, chỉ cần sửa một chỗ duy nhất thay vì tìm
/// string literal rải rác khắp repository.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String observations = 'observations';
  static const String categories = 'categories';
  static const String tags = 'tags';
  static const String collections = 'collections';
  static const String expeditions = 'expeditions';
  static const String areas = 'areas';
  static const String missions = 'missions';
  static const String achievements = 'achievements';
  static const String reports = 'reports';
  static const String notifications = 'notifications';
}

/// Vai trò của User trong hệ thống.
/// Theo tài liệu concept: chỉ 2 role, KHÔNG tạo thêm Contributor/Moderator.
class UserRole {
  UserRole._();

  static const String user = 'user';
  static const String admin = 'admin';
}

/// Trạng thái của Observation — dùng Soft Delete thay vì xóa vật lý
/// (theo tài liệu 8.3), giúp tránh mất dữ liệu và thuận tiện moderation.
class ObservationStatus {
  ObservationStatus._();

  static const String active = 'active';
  static const String deleted = 'deleted';
}

/// Rarity do User tự đánh giá khi tạo Observation (theo tài liệu 8.11).
/// Phiên bản đầu: chỉ có User-selected rarity, chưa có Community Rarity
/// Score — điều đó để dành cho phase AI/Community sau này.
class ObservationRarity {
  ObservationRarity._();

  static const String common = 'common';
  static const String uncommon = 'uncommon';
  static const String rare = 'rare';
  static const String veryRare = 'very_rare';

  static const List<String> values = [common, uncommon, rare, veryRare];

  static String label(String value) {
    switch (value) {
      case uncommon:
        return 'Uncommon';
      case rare:
        return 'Rare';
      case veryRare:
        return 'Very Rare';
      case common:
      default:
        return 'Common';
    }
  }
}

class AppConstants {
  AppConstants._();

  static const String appName = 'Urban Archaeology';

  // Validation
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 20;
  static const int passwordMinLength = 6;

  // Observation
  static const int minPhotosPerObservation = 1;
  static const int maxPhotosPerObservation = 6;
  static const int titleMaxLength = 80;
  static const int descriptionMaxLength = 1000;
}

/// Danh sách Category mặc định, đúng theo ví dụ ở tài liệu (8.6).
///
/// Về nguyên tắc, Category nên do Admin quản lý qua Firestore, không
/// hard-code trong app. Nhưng vì Admin Dashboard chưa được xây (đó là
/// Phase 7), danh sách này chỉ dùng làm SEED DATA — CategoryService sẽ
/// ghi các document này vào Firestore đúng 1 lần (qua nút "Khởi tạo danh
/// mục mặc định" khi collection `categories` đang trống), sau đó toàn bộ
/// app đọc Category từ Firestore như bình thường, không đọc từ hằng số
/// này nữa.
class DefaultCategories {
  DefaultCategories._();

  static const List<Map<String, String>> seed = [
    {'icon': '🪧', 'name': 'Sign / Advertisement'},
    {'icon': '🏛️', 'name': 'Architecture'},
    {'icon': '🏪', 'name': 'Commercial Trace'},
    {'icon': '🧱', 'name': 'Urban Structure'},
    {'icon': '🏚️', 'name': 'Abandoned'},
    {'icon': '🚪', 'name': 'Door / Window'},
    {'icon': '🛠️', 'name': 'Infrastructure'},
    {'icon': '✨', 'name': 'Interesting Place'},
    {'icon': '📦', 'name': 'Other'},
  ];
}

/// Danh sách Achievement mặc định (Phase 5) — cùng logic seed-1-lần
/// như DefaultCategories: AchievementService ghi các document này vào
/// Firestore đúng 1 lần qua nút "Khởi tạo Achievement mặc định", sau
/// đó app đọc từ Firestore như bình thường.
///
/// `conditionType` khớp với AchievementConditionType trong
/// achievement_model.dart. `conditionValue`:
/// - observationCount/expeditionCount: số lượng tối thiểu
/// - rarityFound: rank tối thiểu (0=common, 1=uncommon, 2=rare, 3=very_rare)
/// - totalDistance: mét tối thiểu
class DefaultAchievements {
  DefaultAchievements._();

  static const List<Map<String, dynamic>> seed = [
    {
      'name': 'Người mới bắt đầu',
      'description': 'Tạo Observation đầu tiên của bạn',
      'icon': '🎉',
      'xpReward': 20,
      'conditionType': 'observationCount',
      'conditionValue': 1,
    },
    {
      'name': 'Nhà khảo cổ tập sự',
      'description': 'Tạo 10 Observation',
      'icon': '🔍',
      'xpReward': 50,
      'conditionType': 'observationCount',
      'conditionValue': 10,
    },
    {
      'name': 'Nhà khảo cổ kỳ cựu',
      'description': 'Tạo 50 Observation',
      'icon': '🏆',
      'xpReward': 150,
      'conditionType': 'observationCount',
      'conditionValue': 50,
    },
    {
      'name': 'Bước chân đầu tiên',
      'description': 'Hoàn thành chuyến thám hiểm đầu tiên',
      'icon': '🥾',
      'xpReward': 20,
      'conditionType': 'expeditionCount',
      'conditionValue': 1,
    },
    {
      'name': 'Người lữ hành',
      'description': 'Hoàn thành 10 chuyến thám hiểm',
      'icon': '🧭',
      'xpReward': 100,
      'conditionType': 'expeditionCount',
      'conditionValue': 10,
    },
    {
      'name': 'Săn đồ hiếm',
      'description': 'Tìm được 1 phát hiện độ hiếm Rare trở lên',
      'icon': '💎',
      'xpReward': 50,
      'conditionType': 'rarityFound',
      'conditionValue': 2,
    },
    {
      'name': 'Săn đồ huyền thoại',
      'description': 'Tìm được 1 phát hiện Very Rare',
      'icon': '✨',
      'xpReward': 100,
      'conditionType': 'rarityFound',
      'conditionValue': 3,
    },
    {
      'name': 'Nhà thám hiểm đường dài',
      'description': 'Đi bộ tổng cộng 5km qua các chuyến thám hiểm',
      'icon': '🚶',
      'xpReward': 80,
      'conditionType': 'totalDistance',
      'conditionValue': 5000,
    },
  ];
}

/// Danh sách Mission mẫu (Phase 8 — Hidden in Plain Sight). Cùng cách
/// seed-1-lần như Category/Achievement. `targetCategoryId` để trống ở
/// đây vì phụ thuộc vào id Category thật trên Firestore của từng máy
/// (khác nhau mỗi lần seed) — Admin cần tự gán Category cho Mission
/// loại "category" qua Admin Dashboard sau khi seed xong.
class DefaultMissions {
  DefaultMissions._();

  static const List<Map<String, dynamic>> seed = [
    {
      'title': 'Người mới nhập môn',
      'description': 'Tạo 3 Observation bất kỳ',
      'icon': '🔰',
      'type': 'quantity',
      'targetValue': 3,
      'rewardXp': 30,
    },
    {
      'title': 'Nhà sưu tầm',
      'description': 'Tạo 15 Observation bất kỳ',
      'icon': '📸',
      'type': 'quantity',
      'targetValue': 15,
      'rewardXp': 100,
    },
    {
      'title': 'Người lữ hành bền bỉ',
      'description': 'Đi bộ tổng cộng 2km qua các chuyến thám hiểm',
      'icon': '🥾',
      'type': 'distance',
      'targetValue': 2000,
      'rewardXp': 50,
    },
    {
      'title': 'Người đi xa',
      'description': 'Đi bộ tổng cộng 10km qua các chuyến thám hiểm',
      'icon': '🏔️',
      'type': 'distance',
      'targetValue': 10000,
      'rewardXp': 200,
    },
  ];
}
