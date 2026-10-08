import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/ai_config.dart';
import '../../observation/models/observation_model.dart';
import '../models/ai_models.dart';

/// Lớp giao tiếp duy nhất với AI Backend (server Python).
///
/// Nguyên tắc xuyên suốt: **mọi lỗi đều được nuốt, trả về giá trị
/// rỗng thay vì ném ngoại lệ**. Lý do: AI ở đây là tính năng phụ trợ
/// (gợi ý, cảnh báo) — nếu server tắt, mất mạng, hay trả về dữ liệu
/// lạ, app vẫn phải chạy trơn tru chứ không được chặn người dùng tạo
/// Observation hay xem bản đồ.
class AiService {
  final http.Client _client;

  AiService([http.Client? client]) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('${AiConfig.baseUrl}$path');

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    if (!AiConfig.enabled) return null;

    try {
      final response = await _client
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(AiConfig.timeout);

      if (response.statusCode != 200) {
        debugPrint('AI [$path] trả về mã ${response.statusCode}');
        return null;
      }
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AI [$path] lỗi: $e');
      return null;
    }
  }

  /// Kiểm tra server có đang chạy không — dùng để hiện trạng thái
  /// trong màn gợi ý, giúp người dùng (và bạn lúc demo) biết ngay vì
  /// sao không có kết quả thay vì tưởng app hỏng.
  Future<bool> ping() async {
    if (!AiConfig.enabled) return false;
    try {
      final response =
          await _client.get(_uri('/')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Gửi ảnh mới + embedding của các Observation lân cận, nhận về kết
  /// quả có trùng lặp hay không, KÈM embedding của chính ảnh mới.
  Future<DuplicateCheckResult> checkDuplicate({
    required File image,
    required List<({String observationId, List<double> embedding})> candidates,
  }) async {
    final bytes = await image.readAsBytes();

    final data = await _post('/check-duplicate', {
      'image_base64': base64Encode(bytes),
      'threshold': AiConfig.duplicateThreshold,
      'candidates': candidates
          .map((c) => {
                'observation_id': c.observationId,
                'embedding': c.embedding,
              })
          .toList(),
    });

    if (data == null) return DuplicateCheckResult.empty;
    return DuplicateCheckResult.fromMap(data);
  }

  /// Gom cụm các Observation thành "khu vực thú vị".
  Future<List<InterestingArea>> findInterestingAreas(
    List<ObservationModel> observations, {
    double epsMeters = 150,
    int minSamples = 3,
  }) async {
    if (observations.length < minSamples) return [];

    final data = await _post('/interesting-areas', {
      'eps_meters': epsMeters,
      'min_samples': minSamples,
      'observations': observations.map(_toAiJson).toList(),
    });

    if (data == null) return [];
    return ((data['areas'] as List?) ?? [])
        .map((e) => InterestingArea.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Lấy danh sách gợi ý dựa trên sở thích đã thể hiện của user.
  Future<List<Recommendation>> recommend({
    required List<ObservationModel> candidates,
    required List<String> likedCategoryIds,
    required List<String> likedTags,
    required List<String> seenIds,
    double? userLatitude,
    double? userLongitude,
    int limit = 10,
  }) async {
    if (candidates.isEmpty) return [];

    final data = await _post('/recommend', {
      'candidates': candidates.map(_toAiJson).toList(),
      'liked_category_ids': likedCategoryIds,
      'liked_tags': likedTags,
      'seen_ids': seenIds,
      'user_latitude': userLatitude,
      'user_longitude': userLongitude,
      'limit': limit,
    });

    if (data == null) return [];
    return ((data['recommendations'] as List?) ?? [])
        .map((e) => Recommendation.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Chỉ gửi đúng các trường server cần — không gửi cả Observation
  /// (có ảnh, mô tả dài...) để giảm dung lượng request, nhất là khi
  /// gửi hàng trăm Observation cùng lúc cho việc gom cụm.
  Map<String, dynamic> _toAiJson(ObservationModel o) => {
        'id': o.id,
        'latitude': o.latitude,
        'longitude': o.longitude,
        'categoryId': o.categoryId,
        'rarity': o.rarity,
        'tags': o.tags,
      };
}

final aiServiceProvider = Provider<AiService>((ref) => AiService());

/// Trạng thái kết nối tới AI server — `autoDispose` để mỗi lần mở lại
/// màn hình liên quan sẽ kiểm tra lại, thay vì dùng kết quả cũ từ lúc
/// server còn chưa bật.
final aiServerStatusProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(aiServiceProvider).ping();
});
