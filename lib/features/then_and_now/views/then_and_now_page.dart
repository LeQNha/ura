import 'dart:async';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Then & Now Camera — so sánh 1 ảnh Observation cũ với khung camera
/// hiện tại, theo đúng MVP đã chốt trong tài liệu (12.2): chỉ cần
/// Slider + Overlay, KHÔNG cần AI, không cần tự động căn khớp góc nhìn
/// (user tự căn bằng mắt — đúng như tài liệu lưu ý "Camera và ảnh cũ
/// không tự động khớp góc nhìn").
///
/// Đây là công cụ xem trực tiếp (live comparison tool) — KHÔNG lưu lại
/// ảnh ghép/composite (tài liệu ghi "Capture comparison (optional)").
/// Việc ghép + xuất file ảnh so sánh đòi hỏi xử lý pixel phức tạp hơn
/// nhiều và rủi ro cao khi không test được trên thiết bị thật — để lại
/// làm hướng cải tiến tương lai, không ảnh hưởng giá trị WOW cốt lõi
/// (trải nghiệm so sánh trực tiếp ngay lúc đứng tại chỗ).
class ThenAndNowPage extends StatefulWidget {
  final String oldPhotoUrl;
  final String observationTitle;

  const ThenAndNowPage({
    super.key,
    required this.oldPhotoUrl,
    required this.observationTitle,
  });

  @override
  State<ThenAndNowPage> createState() => _ThenAndNowPageState();
}

enum _CompareMode { slider, blend }

class _ThenAndNowPageState extends State<ThenAndNowPage> {
  CameraController? _cameraController;
  String? _cameraError;
  _CompareMode _mode = _CompareMode.slider;
  double _sliderFraction = 0.5; // 0 = toàn ảnh cũ, 1 = toàn camera
  double _blendOpacity = 0.5;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw 'Không tìm thấy camera trên thiết bị.';

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _cameraController = controller);
    } catch (e) {
      if (mounted) setState(() => _cameraError = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildComparisonView(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                const Spacer(),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.4),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.observationTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonView() {
    if (_cameraError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_outlined, size: 44, color: Colors.white54),
              const SizedBox(height: 12),
              Text(_cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _cameraError = null);
                  _initCamera();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54));
    }

    final cameraLayer = _buildCameraLayer();
    final oldPhotoLayer = CachedNetworkImage(
      imageUrl: widget.oldPhotoUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );

    if (_mode == _CompareMode.blend) {
      return GestureDetector(
        // Vuốt ngang để chỉnh opacity — nhanh hơn phải với đúng thanh
        // Slider nhỏ ở dưới, nhưng vẫn giữ Slider cho thao tác chính
        // xác hơn nếu cần.
        child: Stack(
          fit: StackFit.expand,
          children: [
            cameraLayer,
            Opacity(opacity: _blendOpacity, child: oldPhotoLayer),
          ],
        ),
      );
    }

    // Slider mode — ảnh cũ hiện bên trái, camera hiện bên phải, kéo
    // đường phân chia ở giữa để so sánh (kiểu before/after quen thuộc).
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _sliderFraction =
                  (details.localPosition.dx / width).clamp(0.0, 1.0);
            });
          },
          onTapDown: (details) {
            setState(() {
              _sliderFraction =
                  (details.localPosition.dx / width).clamp(0.0, 1.0);
            });
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              cameraLayer,
              ClipRect(
                clipper: _LeftClipper(width * _sliderFraction),
                child: oldPhotoLayer,
              ),
              Positioned(
                left: width * _sliderFraction - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: (width * _sliderFraction - 18).clamp(0, width - 36),
                top: constraints.maxHeight / 2 - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.drag_indicator, size: 20, color: Colors.black54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraLayer() {
    final controller = _cameraController!;
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
        ),
      ),
      child: Column(
        children: [
          if (_mode == _CompareMode.blend)
            Row(
              children: [
                const Icon(Icons.photo, color: Colors.white70, size: 18),
                Expanded(
                  child: Slider(
                    value: _blendOpacity,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _blendOpacity = v),
                  ),
                ),
                const Icon(Icons.camera_alt, color: Colors.white70, size: 18),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Kéo ngang để so sánh ẢNH CŨ (trái) và CAMERA (phải)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeButton(
                  label: 'Trượt',
                  selected: _mode == _CompareMode.slider,
                  onTap: () => setState(() => _mode = _CompareMode.slider),
                ),
                _ModeButton(
                  label: 'Chồng mờ',
                  selected: _mode == _CompareMode.blend,
                  onTap: () => setState(() => _mode = _CompareMode.blend),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Clip chỉ hiện phần bên TRÁI của widget con, tính theo [width] pixel
/// — dùng để "cắt" ảnh cũ chỉ hiện đến đúng vị trí thanh trượt.
class _LeftClipper extends CustomClipper<Rect> {
  final double width;

  _LeftClipper(this.width);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, width, size.height);

  @override
  bool shouldReclip(covariant _LeftClipper oldClipper) =>
      oldClipper.width != width;
}
