import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../map/viewmodels/map_viewmodel.dart';
import '../../map/widgets/observation_preview_card.dart';
import '../../observation/models/observation_model.dart';
import '../widgets/ar_marker_widget.dart';
import '../widgets/compass_badge.dart';
import '../widgets/scanner_math.dart';

/// Vị trí tab Scanner trong bottom nav của HomeShellPage — PHẢI khớp
/// với thứ tự khai báo trong `_tabs` ở home_shell_page.dart. Dùng để
/// biết lúc nào tab này đang thật sự hiển thị, từ đó bật/tắt camera —
/// vì camera là tài nguyên nặng, không nên giữ chạy khi user đang ở
/// tab khác (IndexedStack giữ mọi tab "sống" trong bộ nhớ cùng lúc).
const _scannerTabIndex = 3;

/// Bán kính quét mặc định và các mốc cho user chọn.
const _radiusOptions = [200.0, 500.0, 1000.0];

/// Nửa góc nhìn (FOV) coi là "trong khung hình camera" — ước lượng đơn
/// giản (đa số camera sau của điện thoại có FOV ngang thực tế
/// ~60-80°); có thể tinh chỉnh lại sau khi test trên thiết bị thật,
/// đúng tinh thần "làm đại khái trước, cải thiện sau" đã thống nhất.
const _halfFovDegrees = 40.0;

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _positionSub;
  final _headingSmoother = HeadingSmoother();

  double _heading = 0;
  Position? _position;
  bool _isActiveTab = false;
  bool _cameraInitializing = false;
  String? _cameraError;
  String? _locationError;
  double _radiusMeters = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _teardown();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isActiveTab) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _cameraController?.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      _cameraController?.resumePreview();
    }
  }

  Future<void> _activate() async {
    if (_isActiveTab) return;
    _isActiveTab = true;

    if (_cameraController == null && !_cameraInitializing) {
      await _initCamera();
    } else {
      await _cameraController?.resumePreview();
    }

    _compassSub ??= FlutterCompass.events?.listen((event) {
      final raw = event.heading;
      if (raw == null || !mounted) return;
      setState(() => _heading = _headingSmoother.add(raw));
    });

    if (_positionSub == null) {
      await _startLocationTracking();
    }
  }

  void _deactivate() {
    if (!_isActiveTab) return;
    _isActiveTab = false;
    _cameraController?.pausePreview();
    _compassSub?.cancel();
    _compassSub = null;
    _positionSub?.cancel();
    _positionSub = null;
  }

  void _teardown() {
    _compassSub?.cancel();
    _positionSub?.cancel();
    _cameraController?.dispose();
  }

  Future<void> _initCamera() async {
    setState(() => _cameraInitializing = true);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw 'Không tìm thấy camera trên thiết bị.';
      }
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
      setState(() {
        _cameraController = controller;
        _cameraInitializing = false;
        _cameraError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraInitializing = false;
        _cameraError = e.toString();
      });
    }
  }

  Future<void> _startLocationTracking() async {
    setState(() => _locationError = null);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Vui lòng bật GPS/Dịch vụ vị trí.';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Bạn cần cấp quyền vị trí để dùng Urban Scanner.';
      }

      final initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _position = initial);

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
    } catch (e) {
      if (mounted) setState(() => _locationError = e.toString());
    }
  }

  void _showPreview(ObservationModel observation, double distance) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ObservationPreviewCard(
        observation: observation,
        distanceInMeters: distance,
        onTap: () {
          Navigator.pop(context);
          context.push('/observation/${observation.id}');
        },
      ),
    );
  }

  List<({ObservationModel observation, double distance, double signedAngle})>
      _computeVisibleMarkers(List<ObservationModel> all) {
    if (_position == null) return [];

    final result = <({
      ObservationModel observation,
      double distance,
      double signedAngle
    })>[];

    for (final o in all) {
      final distance = Geolocator.distanceBetween(
        _position!.latitude,
        _position!.longitude,
        o.latitude,
        o.longitude,
      );
      if (distance > _radiusMeters) continue;

      final bearing = (Geolocator.bearingBetween(
                _position!.latitude,
                _position!.longitude,
                o.latitude,
                o.longitude,
              ) +
              360) %
          360;
      final signedAngle = shortestAngleDiff(_heading, bearing);
      if (signedAngle.abs() > _halfFovDegrees) continue;

      result.add((observation: o, distance: distance, signedAngle: signedAngle));
    }

    // Xa vẽ trước, gần vẽ sau (đè lên trên) — tạo cảm giác chiều sâu.
    result.sort((a, b) => b.distance.compareTo(a.distance));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabIndexProvider);
    final shouldBeActive = selectedTab == _scannerTabIndex;

    // Bật/tắt camera + sensor theo đúng lúc tab này thật sự hiển thị —
    // tránh giữ camera chạy ngầm tốn pin khi user đang ở tab khác.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldBeActive && !_isActiveTab) {
        _activate();
      } else if (!shouldBeActive && _isActiveTab) {
        _deactivate();
      }
    });

    if (!shouldBeActive) {
      // Không hiển thị nội dung camera khi không phải tab active —
      // tránh lãng phí công vẽ + đảm bảo không lộ khung hình cũ.
      return const ColoredBox(color: Colors.black);
    }

    final allObservations = ref.watch(mapObservationsProvider).valueOrNull ?? [];
    final markers = _computeVisibleMarkers(allObservations);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraBackground(),

          // AR markers
          ...markers.map((m) {
            final ratio = 0.5 + (m.signedAngle / _halfFovDegrees) * 0.5;
            final depthScale =
                (1 - (m.distance / _radiusMeters) * 0.6).clamp(0.4, 1.0);
            final jitter = (m.observation.id.hashCode % 5 - 2) * 14.0;

            return Positioned(
              left: (ratio * screenWidth) - 26,
              top: (screenHeight * 0.42) + jitter - 26,
              child: ArMarkerWidget(
                observation: m.observation,
                distanceMeters: m.distance,
                depthScale: depthScale,
                onTap: () => _showPreview(m.observation, m.distance),
              ),
            );
          }),

          // Crosshair giữa màn hình — mốc tham chiếu hướng camera đang
          // chỉ thẳng vào, giúp user hiểu logic "marker lệch trái/phải
          // theo hướng cầm máy".
          Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CompassBadge(heading: _heading),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${markers.length} dấu vết',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_locationError != null) _buildErrorBanner(_locationError!),
                  const Spacer(),
                  _buildRadiusSelector(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraBackground() {
    if (_cameraError != null) {
      return _buildFullscreenMessage(
        icon: Icons.videocam_off_outlined,
        message: _cameraError!,
        onRetry: _initCamera,
      );
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

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

  Widget _buildFullscreenMessage({
    required IconData icon,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
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

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 12.5),
      ),
    );
  }

  Widget _buildRadiusSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _radiusOptions.map((r) {
          final selected = r == _radiusMeters;
          return GestureDetector(
            onTap: () => setState(() => _radiusMeters = r),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                r >= 1000 ? '${(r / 1000).toStringAsFixed(0)}km' : '${r.toInt()}m',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
