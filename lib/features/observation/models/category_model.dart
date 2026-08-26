import 'package:cloud_firestore/cloud_firestore.dart';

/// Category entity (tài liệu 8.6) — dùng để phân loại Observation.
///
/// Về lâu dài Category do Admin quản lý trên Firestore. Ở Phase 1, app
/// chỉ ĐỌC category từ Firestore + có 1 nút seed dữ liệu mặc định 1 lần
/// (xem DefaultCategories trong app_constants.dart) — chưa có UI để
/// Admin tạo/sửa/xóa Category (đó là Phase Admin Dashboard).
class CategoryModel {
  final String id;
  final String name;
  final String icon; // emoji, hiển thị trực tiếp không cần asset riêng
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.order = 0,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '📦',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  factory CategoryModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CategoryModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'icon': icon, 'order': order};
  }
}
