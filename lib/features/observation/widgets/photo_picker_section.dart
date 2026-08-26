import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

/// Lưới ảnh cho bước "Photos" của Create Observation.
///
/// Tự xử lý việc gọi ImagePicker (Camera/Gallery) ngay trong widget này
/// thay vì đẩy logic lên ViewModel — vì ImagePicker cần BuildContext để
/// hiện bottom sheet chọn nguồn ảnh, và bản thân việc "mở camera" là
/// một hành vi UI, không phải business logic cần test riêng.
class PhotoPickerSection extends StatelessWidget {
  final List<File> photos;
  final void Function(List<File> newPhotos) onPhotosPicked;
  final void Function(int index) onRemove;

  const PhotoPickerSection({
    super.key,
    required this.photos,
    required this.onPhotosPicked,
    required this.onRemove,
  });

  bool get _canAddMore => photos.length < AppConstants.maxPhotosPerObservation;

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
                final photo =
                    await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                if (photo != null) {
                  onPhotosPicked([File(photo.path)]);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final remaining =
                    AppConstants.maxPhotosPerObservation - photos.length;
                final picked = await picker.pickMultiImage(imageQuality: 85);
                if (picked.isNotEmpty) {
                  final files = picked
                      .take(remaining)
                      .map((x) => File(x.path))
                      .toList();
                  onPhotosPicked(files);
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
      itemCount: photos.length + (_canAddMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == photos.length) {
          return _AddTile(onTap: () => _showSourcePicker(context));
        }
        return _PhotoTile(
          file: photos[index],
          isCover: index == 0,
          onRemove: () => onRemove(index),
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
      child: DottedBorderBox(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            SizedBox(height: 4),
            Text(
              'Thêm ảnh',
              style: TextStyle(fontSize: 11, color: AppColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung nét đứt đơn giản vẽ bằng CustomPaint — tránh phụ thuộc thêm
/// package ngoài chỉ để vẽ 1 khung viền nét đứt.
class DottedBorderBox extends StatelessWidget {
  final Widget child;

  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PhotoTile extends StatelessWidget {
  final File file;
  final bool isCover;
  final VoidCallback onRemove;

  const _PhotoTile({
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
        if (isCover)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Ảnh bìa',
                style: TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        Positioned(
          right: 2,
          top: 2,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
