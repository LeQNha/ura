import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';
import '../errors/app_exceptions.dart';

/// Service upload ảnh lên Cloudinary.
///
/// Đặt ở core/ (không nằm trong features/observation/) vì đây là hạ
/// tầng dùng chung — sau này Profile (avatar) hay Comment (ảnh đính
/// kèm) cũng sẽ dùng lại chính service này.
class CloudinaryService {
  /// Upload 1 ảnh, trả về secure URL của ảnh trên Cloudinary.
  ///
  /// [folder] giúp tổ chức ảnh trên Cloudinary theo mục đích sử dụng
  /// (vd 'observations', 'avatars') để dễ quản lý/dọn dẹp sau này.
  Future<String> uploadImage(File imageFile, {required String folder}) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const AppException(
        'Chưa cấu hình Cloudinary. Xem README_PHASE1.md mục "Setup Cloudinary".',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw AppException(
          'Upload ảnh thất bại (mã lỗi ${response.statusCode}).',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['secure_url'] as String?;
      if (url == null) {
        throw const AppException('Cloudinary không trả về URL ảnh hợp lệ.');
      }
      return url;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Lỗi kết nối khi upload ảnh: $e');
    }
  }

  /// Upload nhiều ảnh tuần tự, trả về danh sách URL theo đúng thứ tự.
  ///
  /// Upload tuần tự (không Future.wait song song) để [onProgress] báo
  /// tiến độ chính xác từng ảnh một — người dùng trên thực địa thường
  /// có mạng yếu, upload dồn dập cùng lúc dễ timeout cả loạt.
  Future<List<String>> uploadImages(
    List<File> images, {
    required String folder,
    void Function(int uploaded, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      final url = await uploadImage(images[i], folder: folder);
      urls.add(url);
      onProgress?.call(i + 1, images.length);
    }
    return urls;
  }
}

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});
