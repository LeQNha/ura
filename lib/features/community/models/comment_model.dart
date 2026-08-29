import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment entity — lưu dạng subcollection `observations/{id}/comments`
/// (không phải array field trên Observation) vì số lượng comment có
/// thể tăng không giới hạn theo thời gian, không phù hợp nhồi vào 1
/// document duy nhất như Tag (vốn cố định, ít thay đổi).
class CommentModel {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['createdAt'];
    return CommentModel(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      authorUsername: map['authorUsername'] as String? ?? 'unknown',
      authorAvatarUrl: map['authorAvatarUrl'] as String?,
      text: map['text'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  factory CommentModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return CommentModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorAvatarUrl': authorAvatarUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
