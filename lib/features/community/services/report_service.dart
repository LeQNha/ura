import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore;

  ReportService(this._firestore);

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection(FirestoreCollections.reports);

  Future<void> createReport(ReportModel report) async {
    try {
      await _reportsRef.add(report.toMap());
    } catch (e) {
      throw AppException('Không thể gửi báo cáo: $e');
    }
  }

  /// Lấy TẤT CẢ report (không lọc status trong query) rồi để UI tự lọc
  /// pending/resolved ở client — tránh phải kết hợp `where` + `orderBy`
  /// trên 2 field khác nhau (sẽ cần Composite Index), giữ đúng hướng
  /// "lọc đơn giản ở client" đã thống nhất từ Phase Map.
  Stream<List<ReportModel>> watchAllReports() {
    return _reportsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReportModel.fromSnapshot).toList());
  }

  Future<void> resolveReport(String reportId) async {
    try {
      await _reportsRef.doc(reportId).update({'status': ReportStatus.resolved});
    } catch (e) {
      throw AppException('Không thể cập nhật báo cáo: $e');
    }
  }
}

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.watch(firestoreProvider));
});
