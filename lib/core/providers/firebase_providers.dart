import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Providers cho các instance Firebase gốc.
///
/// Đây là "gốc" của dependency graph:
///   FirebaseAuth / Firestore  →  Service  →  Repository  →  ViewModel  →  View
///
/// Đặt riêng ở core/ (không nằm trong features/) vì đây là hạ tầng dùng
/// chung cho mọi feature, không thuộc riêng feature nào.

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});
