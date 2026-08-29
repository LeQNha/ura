import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/services/auth_service.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore;

  CategoryService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection(FirestoreCollections.categories);

  Stream<List<CategoryModel>> watchCategories() {
    return _categoriesRef.orderBy('order').snapshots().map(
          (snap) => snap.docs.map(CategoryModel.fromSnapshot).toList(),
        );
  }

  Future<List<CategoryModel>> getCategoriesOnce() async {
    final snap = await _categoriesRef.orderBy('order').get();
    return snap.docs.map(CategoryModel.fromSnapshot).toList();
  }

  /// Ghi danh sách Category mặc định (DefaultCategories.seed) vào
  /// Firestore — chỉ nên gọi khi collection đang trống. Dùng batch write
  /// để đảm bảo tất cả category được tạo cùng lúc hoặc không cái nào cả.
  Future<void> seedDefaultCategories() async {
    final batch = _firestore.batch();
    for (var i = 0; i < DefaultCategories.seed.length; i++) {
      final item = DefaultCategories.seed[i];
      final docRef = _categoriesRef.doc();
      batch.set(docRef, {
        'name': item['name'],
        'icon': item['icon'],
        'order': i,
      });
    }
    await batch.commit();
  }

  /// Tạo 1 Category đơn lẻ — dùng ở Admin Dashboard (Phase 7), khác với
  /// seedDefaultCategories() (ghi hàng loạt, chỉ dùng lúc khởi tạo).
  Future<void> createCategory({
    required String name,
    required String icon,
    required int order,
  }) async {
    await _categoriesRef.add({'name': name, 'icon': icon, 'order': order});
  }

  Future<void> updateCategory(
    String id, {
    required String name,
    required String icon,
  }) async {
    await _categoriesRef.doc(id).update({'name': name, 'icon': icon});
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesRef.doc(id).delete();
  }
}

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CategoryService(firestore);
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  // Đợi auth xác nhận xong mới bắn query — tránh race condition
  // permission-denied ngay sau đăng nhập/đăng ký (xem giải thích chi
  // tiết ở observation_feed_viewmodel.dart).
  final authState = ref.watch(authStateChangesProvider);
  if (authState.valueOrNull == null) return Stream.value(<CategoryModel>[]);

  final service = ref.watch(categoryServiceProvider);
  return service.watchCategories();
});
