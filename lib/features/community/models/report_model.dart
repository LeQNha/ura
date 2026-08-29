import 'package:cloud_firestore/cloud_firestore.dart';

class ReportStatus {
  ReportStatus._();

  static const String pending = 'pending';
  static const String resolved = 'resolved';
}

/// Lý do report cố định (đơn giản hóa — không cho tự do nhập lý do để
/// dễ Admin lọc/thống kê).
class ReportReason {
  ReportReason._();

  static const List<String> options = [
    'Nội dung không phù hợp',
    'Spam / quảng cáo',
    'Thông tin sai lệch',
    'Vi phạm bản quyền',
    'Khác',
  ];
}

/// Report entity — user báo cáo 1 Observation vi phạm, Admin xử lý ở
/// Dashboard (xóa Observation hoặc bỏ qua báo cáo).
class ReportModel {
  final String id;
  final String observationId;
  final String observationTitle; // denormalized để Admin xem nhanh
  final String reporterId;
  final String reporterUsername;
  final String reason;
  final String status;
  final DateTime createdAt;

  const ReportModel({
    required this.id,
    required this.observationId,
    required this.observationTitle,
    required this.reporterId,
    required this.reporterUsername,
    required this.reason,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    return ReportModel(
      id: id,
      observationId: map['observationId'] as String? ?? '',
      observationTitle: map['observationTitle'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      reporterUsername: map['reporterUsername'] as String? ?? '',
      reason: map['reason'] as String? ?? '',
      status: map['status'] as String? ?? ReportStatus.pending,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  factory ReportModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ReportModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'observationId': observationId,
      'observationTitle': observationTitle,
      'reporterId': reporterId,
      'reporterUsername': reporterUsername,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
