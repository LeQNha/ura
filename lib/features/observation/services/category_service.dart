import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/firebase_providers.dart';
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
}

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CategoryService(firestore);
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final service = ref.watch(categoryServiceProvider);
  return service.watchCategories();
});
