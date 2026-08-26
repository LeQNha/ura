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
