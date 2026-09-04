import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Lưới quản lý ảnh cho màn Chỉnh sửa Observation — khác với
/// PhotoPickerSection (Phase 1, chỉ xử lý ảnh mới local), widget này
/// xử lý ĐỒNG THỜI 2 nguồn: ảnh cũ đã có trên Cloudinary (hiển thị qua
/// URL) và ảnh mới vừa chọn thêm (còn nằm trên máy, chưa upload).
/// Ảnh cũ luôn xếp trước, ảnh mới nối tiếp sau — ảnh đầu tiên trong
/// tổng thứ tự này sẽ là ảnh bìa sau khi lưu.
class EditPhotoGrid extends StatelessWidget {
  final List<String> existingUrls;
  final List<File> newFiles;
  final void Function(int index) onRemoveExisting;
  final void Function(int index) onRemoveNew;
  final void Function(List<File> files) onAddFiles;

  const EditPhotoGrid({
    super.key,
    required this.existingUrls,
    required this.newFiles,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    required this.onAddFiles,
  });

  int get _totalCount => existingUrls.length + newFiles.length;
  bool get _canAddMore => _totalCount < AppConstants.maxPhotosPerObservation;

  Future<void> _showSourcePicker(BuildContext context) async {
    final picker = ImagePicker();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDAD7D0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Chụp ảnh mới'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final photo = await picker.pickImage(
                    source: ImageSource.camera, imageQuality: 85);
                if (photo != null) onAddFiles([File(photo.path)]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final remaining =
                    AppConstants.maxPhotosPerObservation - _totalCount;
                final picked = await picker.pickMultiImage(imageQuality: 85);
                if (picked.isNotEmpty) {
                  onAddFiles(
                    picked.take(remaining).map((x) => File(x.path)).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _totalCount + (_canAddMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _totalCount) {
          return _AddTile(onTap: () => _showSourcePicker(context));
        }
        final isCover = index == 0;
        if (index < existingUrls.length) {
          return _ExistingPhotoTile(
            url: existingUrls[index],
            isCover: isCover,
            onRemove: () => onRemoveExisting(index),
          );
        }
        final newIndex = index - existingUrls.length;
        return _NewPhotoTile(
          file: newFiles[newIndex],
          isCover: isCover,
          onRemove: () => onRemoveNew(newIndex),
        );
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withOpacity(0.05),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            SizedBox(height: 4),
            Text('Thêm ảnh',
                style: TextStyle(fontSize: 11, color: AppColors.primaryDark)),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 2,
      top: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
              color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      bottom: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Ảnh bìa',
            style: TextStyle(color: Colors.white, fontSize: 9)),
      ),
    );
  }
}

class _ExistingPhotoTile extends StatelessWidget {
  final String url;
  final bool isCover;
  final VoidCallback onRemove;

  const _ExistingPhotoTile({
    required this.url,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
        ),
        if (isCover) const _CoverBadge(),
        _RemoveButton(onTap: onRemove),
      ],
    );
  }
}

class _NewPhotoTile extends StatelessWidget {
  final File file;
  final bool isCover;
  final VoidCallback onRemove;

  const _NewPhotoTile({
    required this.file,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, fit: BoxFit.cover),
        ),
        if (isCover) const _CoverBadge(),
        _RemoveButton(onTap: onRemove),
      ],
    );
  }
}
