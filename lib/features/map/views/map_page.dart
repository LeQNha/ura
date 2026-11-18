import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/providers/navigation_providers.dart';
import '../../../core/services/nominatim_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../observation/models/observation_model.dart';
import '../viewmodels/map_viewmodel.dart';
import '../widgets/address_search_sheet.dart';
import '../widgets/map_filter_sheet.dart';
import '../widgets/map_markers.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/observation_preview_card.dart';
import '../../ai/widgets/interesting_area_layer.dart';
import '../widgets/island_labels_layer.dart';

/// Tọa độ fallback khi chưa xác định được vị trí user và chưa có
/// Observation nào để tự căn giữa bản đồ — trung tâm địa lý Việt Nam.
/// Chỉ dùng tạm lúc khởi động, sẽ bị thay ngay khi có dữ liệu thật.
const _fallbackCenter = LatLng(16.0471, 108.2062);
const _fallbackZoom = 5.0;

/// Vị trí của tab Bản đồ trong `HomeShellPage._tabs` (Map = 0, Feed = 1,
/// Scanner = 2). PHẢI khớp với thứ tự tab ở home_shell_page.dart — đổi
/// thứ tự tab thì phải sửa cả hằng số này (cùng ràng buộc với
/// `_scannerTabIndex` ở scanner_page.dart).
const _mapTabIndex = 0;

/// Mức zoom khi căn bản đồ vào vị trí người dùng lần đầu.
const _initialLocationZoom = 14.0;

/// Mức zoom khi bật chế độ "bám theo vị trí" (đi bộ nên zoom gần hơn).
const _followZoom = 16.0;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with WidgetsBindingObserver {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  /// Vị trí HIỆN TẠI của người dùng, được cập nhật liên tục khi họ di
  /// chuyển. Dùng [ValueNotifier] thay vì `setState`: mỗi lần di chuyển chỉ
  /// vẽ lại chấm xanh, không phải vẽ lại cả bản đồ cùng hàng trăm marker.
  final _userLocationNotifier = ValueNotifier<LatLng?>(null);
  LatLng? get _userLocation => _userLocationNotifier.value;

  /// Luồng GPS liên tục. `null` = đang không theo dõi.
  StreamSubscription<Position>? _positionSub;
  bool _startingTracking = false;

  /// `true` = bản đồ tự dịch chuyển theo người dùng. Tự tắt khi họ kéo
  /// hoặc zoom bản đồ bằng tay (xem `onPositionChanged` ở `build`).
  bool _followUser = false;

  bool _hasCenteredOnData = false;
  double _mapZoom = _fallbackZoom;

  // "Tìm địa điểm" (Nominatim) — khác với ô search phía trên vốn lọc
  // Observation đang có, đây là kết quả tìm địa danh THẬT để bay bản
  // đồ tới, không liên quan gì đến dữ liệu Observation.
  LatLng? _searchedLocation;
  String? _searchedLocationLabel;

  /// Tab Bản đồ có đang được hiển thị không. `HomeShellPage` dùng
  /// IndexedStack nên cả 3 tab đều "sống" cùng lúc; nếu không kiểm tra thì
  /// GPS sẽ chạy ngầm cả khi người dùng đang ở tab khác, rất tốn pin.
  bool get _isMapTabActive =>
      ref.read(selectedTabIndexProvider) == _mapTabIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMapTabActive) _startTracking(centerOnFirstFix: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    _userLocationNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// App xuống nền thì dừng GPS (tiết kiệm pin); quay lại thì chạy tiếp.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isMapTabActive) _startTracking();
    } else if (state == AppLifecycleState.paused) {
      _stopTracking();
    }
  }

  /// Bắt đầu THEO DÕI vị trí liên tục (thay cho việc chỉ lấy 1 lần như trước).
  ///
  /// Trên Map việc có vị trí chỉ là tiện ích thêm nên hàm này "best-effort":
  /// không ném lỗi. Nó trả về thông báo lỗi tiếng Việt (để nơi gọi quyết
  /// định có hiện hay không), hoặc `null` nếu ổn / đang theo dõi rồi.
  ///
  /// [centerOnFirstFix]: căn camera vào vị trí đầu tiên nhận được.
  Future<String?> _startTracking({
    bool centerOnFirstFix = false,
    double zoom = _initialLocationZoom,
  }) async {
    if (_positionSub != null || _startingTracking) return null;
    _startingTracking = true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return 'Vui lòng bật GPS/Dịch vụ vị trí.';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Bạn cần cấp quyền vị trí để xem vị trí của mình trên bản đồ.';
      }

      // (1) Vị trí đầu tiên: lấy nhanh (độ chính xác vừa) để chấm xanh hiện
      //     sớm. Thất bại thì bỏ qua, bước (2) sẽ lo tiếp.
      try {
        final first = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high, //medium
          timeLimit: const Duration(seconds: 8),
        );
        if (!mounted) return null;
        _applyPosition(
          first,
          move: centerOnFirstFix || _followUser,
          zoom: zoom,
        );
      } catch (_) {
        // Chưa lấy được ngay: vẫn đăng ký luồng bên dưới, vị trí sẽ tới sau.
      }

      // (2) Theo dõi liên tục: mỗi lần người dùng di chuyển ≥ 5 mét thì
      //     nhận 1 vị trí mới và cập nhật chấm xanh.
      if (!mounted || !_isMapTabActive || _positionSub != null) return null;
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          if (!mounted) return;
          _applyPosition(position, move: _followUser, zoom: _followZoom);
        },
        // GPS bị tắt giữa chừng, mất quyền... → dừng; lần bật lại tab hoặc
        // bấm nút vị trí sẽ thử khởi động lại.
        onError: (_) => _stopTracking(),
      );
      return null;
    } catch (_) {
      return 'Không thể xác định vị trí của bạn.';
    } finally {
      _startingTracking = false;
    }
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  /// Ghi nhận vị trí mới: cập nhật chấm xanh, và nếu [move] thì dời camera.
  void _applyPosition(
    Position position, {
    required bool move,
    required double zoom,
  }) {
    final latLng = LatLng(position.latitude, position.longitude);
    _userLocationNotifier.value = latLng;
    if (move) _safeMove(latLng, zoom);
  }

  void _safeMove(LatLng target, double zoom) {
    try {
      _mapController.move(target, zoom);
    } catch (_) {
      // Bản đồ chưa sẵn sàng (vừa mở) → bỏ qua, lần cập nhật sau sẽ thử lại.
    }
  }

  /// Nút "Vị trí của tôi":
  ///   - đang bám theo  → bấm để TẮT bám theo (camera đứng yên);
  ///   - chưa bám theo → căn camera vào vị trí hiện tại và BẬT bám theo.
  Future<void> _onMyLocationPressed() async {
    //if để tránh bấm liên tục nhiều lần -> GPS bị khởi động lại nhiều lần, gây lag.
    if (_followUser) {
      setState(() => _followUser = false);
      return;
    }

    setState(() => _followUser = true);

    final current = _userLocation;
    if (_positionSub != null && current != null) {
      _safeMove(current, _followZoom);
      return;
    }

    // Chưa theo dõi / chưa có vị trí: khởi động, camera sẽ tự căn khi có
    // vị trí đầu tiên.
    final error = await _startTracking(
      centerOnFirstFix: true,
      zoom: _followZoom,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => _followUser = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _centerOnDataIfNeeded(List<ObservationModel> observations) {
    if (_hasCenteredOnData || _userLocation != null || observations.isEmpty) {
      return;
    }
    _hasCenteredOnData = true;

    // những cái này để tính trung bình tọa độ của tất cả các observation, để căn bản đồ vào giữa chúng.
    final avgLat = observations.map((o) => o.latitude).reduce((a, b) => a + b) /
        observations.length;
    final avgLng =
        observations.map((o) => o.longitude).reduce((a, b) => a + b) /
            observations.length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(LatLng(avgLat, avgLng), 12);
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const MapFilterSheet(),
    );
  }

  void _openAddressSearch() {
    showAddressSearchSheet(
      context,
      onSelected: (NominatimPlace place) {
        final latLng = LatLng(place.latitude, place.longitude);
        setState(() {
          _searchedLocation = latLng;
          _searchedLocationLabel = place.displayName;
        });
        _mapController.move(latLng, 16);
      },
    );
  }

  void _clearSearchedLocation() {
    setState(() {
      _searchedLocation = null;
      _searchedLocationLabel = null;
    });
  }

  void _showPreview(ObservationModel observation) {
    double? distance;
    if (_userLocation != null) {
      distance = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        observation.latitude,
        observation.longitude,
      );
    }

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

  @override
  Widget build(BuildContext context) {
    // Chỉ theo dõi GPS khi đang đứng ở tab Bản đồ: rời tab thì dừng, quay
    // lại thì chạy tiếp.
    ref.listen<int>(selectedTabIndexProvider, (previous, next) {
      if (next == _mapTabIndex) {
        _startTracking();
      } else {
        _stopTracking();
      }
    });

    final observations = ref.watch(filteredMapObservationsProvider);
    final filter = ref.watch(mapFilterProvider);

    _centerOnDataIfNeeded(observations);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _fallbackCenter,
              initialZoom: _fallbackZoom,
              minZoom: 3,
              maxZoom: 19,
              // Người dùng tự kéo/zoom bản đồ → ngừng bám theo vị trí, để
              // không giằng co với thao tác của họ.
              // onPositionChanged: (_, hasGesture) {
              //   if (hasGesture && _followUser) {
              //     setState(() => _followUser = false);
              //   }
              // },
              onPositionChanged: (camera, hasGesture) {
                final currentZoom = camera.zoom ?? _mapZoom;
                // Kiểm tra mức zoom có thay đổi đủ lớn hay không.
                final zoomChanged = (currentZoom - _mapZoom).abs() >= 0.25;

                // Người dùng tự kéo hoặc zoom bản đồ
                // thì ngừng chế độ bám theo vị trí.
                final shouldStopFollowing = hasGesture && _followUser;

                if (zoomChanged || shouldStopFollowing) {
                  setState(() {
                    if (zoomChanged) {
                      _mapZoom = currentZoom;
                    }

                    if (shouldStopFollowing) {
                      _followUser = false;
                    }
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // TODO: đổi thành đúng applicationId của app (trong
                // android/app/build.gradle) trước khi phát hành thật —
                // OSM dùng giá trị này để theo dõi tải, không bắt buộc
                // chính xác tuyệt đối để chạy demo/đồ án.
                userAgentPackageName: 'com.example.urban_archaeology',
                maxZoom: 19,
                // Tạm thời thêm để debug — in lỗi thật ra console thay vì
                // chỉ hiện nền xám im lặng. Sau khi xác định xong nguyên
                // nhân có thể bỏ lại (không bắt buộc phải giữ).
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('❌ Tile load error: $error');
                },
              ),
              const InterestingAreaLayer(),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 50,
                  size: const Size(40, 40),
                  zoomToBoundsOnClick: true,
                  spiderfyCluster: true,
                  polygonOptions: PolygonOptions(
                    borderColor: Colors.transparent,
                    color: Colors.transparent,
                    borderStrokeWidth: 0,
                  ),
                  markers: observations.map((o) {
                    return Marker(
                      point: LatLng(o.latitude, o.longitude),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showPreview(o),
                        child: ObservationMarkerIcon(observation: o),
                      ),
                    );
                  }).toList(),
                  builder: (context, markers) =>
                      ClusterBubble(count: markers.length),
                ),
              ),
              // Chấm xanh vị trí hiện tại — cập nhật real-time. Bọc trong
              // ValueListenableBuilder nên mỗi lần di chuyển chỉ lớp này vẽ lại.
              ValueListenableBuilder<LatLng?>(
                valueListenable: _userLocationNotifier,
                builder: (context, userLocation, _) {
                  if (userLocation == null) return const SizedBox.shrink();
                  return MarkerLayer(markers: [
                    Marker(
                      point: userLocation,
                      width: 22,
                      height: 22,
                      child: const _UserLocationDot(),
                    ),
                  ]);
                },
              ),
              if (_searchedLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _searchedLocation!,
                    width: 36,
                    height: 36,
                    child: const _SearchedLocationPin(),
                  ),
                ]),
              IslandLabelsLayer(zoom: _mapZoom),
            ],
          ),

          // Attribution bắt buộc theo license OpenStreetMap (ODbL).
          // Positioned(
          //   left: 8,
          //   bottom: 8,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //     color: Colors.white.withOpacity(0.75),
          //     child: const Text(
          //       '© OpenStreetMap contributors',
          //       style: TextStyle(fontSize: 9, color: Colors.black87),
          //     ),
          //   ),
          // ),
          const Positioned(
            left: 8,
            bottom: 8,
            child: _OsmAttribution(),
          ),

          // Search bar + filter
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: MapSearchBar(
                          controller: _searchController,
                          onChanged: (v) =>
                              ref.read(mapFilterProvider.notifier).setQuery(v),
                          onFilterTap: _openFilterSheet,
                          hasActiveFilters:
                              filter.selectedCategoryIds.isNotEmpty,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _CircleActionButton(
                        icon: Icons.place_outlined,
                        onTap: _openAddressSearch,
                      ),
                    ],
                  ),
                  if (_searchedLocationLabel != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _searchedLocationLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          InkWell(
                            onTap: _clearSearchedLocation,
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.close, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (filter.hasActiveFilters && observations.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Không tìm thấy Observation phù hợp với bộ lọc.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // My Location + Create FAB
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              children: [
                const InterestingAreaToggle(),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor:
                      _followUser ? AppColors.primary : AppColors.surfaceLight,
                  foregroundColor:
                      _followUser ? Colors.white : AppColors.primaryDark,
                  tooltip: _followUser
                      ? 'Đang bám theo vị trí của bạn (bấm để tắt)'
                      : 'Vị trí của tôi',
                  onPressed: _onMyLocationPressed,
                  child: Icon(
                    _followUser ? Icons.gps_fixed : Icons.my_location,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'create_observation',
                  onPressed: () => context.push('/create-observation'),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Ghi nhận'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.info,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

/// Nút tròn nổi cạnh thanh search — dùng chung style với khung filter,
/// tách riêng để dễ tái sử dụng nếu sau này thêm hành động khác cạnh
/// search bar.
class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primaryDark),
        onPressed: onTap,
      ),
    );
  }
}

/// Ghim đánh dấu địa điểm vừa tìm qua Nominatim — cố tình khác hình
/// dạng/màu với marker Observation (hình tròn) và chấm vị trí user
/// (chấm xanh), để không bị nhầm là 1 trong 2 loại đó.
class _SearchedLocationPin extends StatelessWidget {
  const _SearchedLocationPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on, size: 36, color: AppColors.error, shadows: [
          Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
        ]),
      ],
    );
  }
}

class _OsmAttribution extends StatefulWidget {
  const _OsmAttribution();

  @override
  State<_OsmAttribution> createState() => _OsmAttributionState();
}

class _OsmAttributionState extends State<_OsmAttribution> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.black54),
              if (_open)
                const Padding(
                  padding: EdgeInsets.only(left: 4, right: 4),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
