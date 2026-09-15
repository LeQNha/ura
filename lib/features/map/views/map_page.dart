import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/nominatim_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../observation/models/observation_model.dart';
import '../viewmodels/map_viewmodel.dart';
import '../widgets/address_search_sheet.dart';
import '../widgets/map_filter_sheet.dart';
import '../widgets/map_markers.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/observation_preview_card.dart';

/// Tọa độ fallback khi chưa xác định được vị trí user và chưa có
/// Observation nào để tự căn giữa bản đồ — trung tâm địa lý Việt Nam.
/// Chỉ dùng tạm lúc khởi động, sẽ bị thay ngay khi có dữ liệu thật.
const _fallbackCenter = LatLng(16.0471, 108.2062);
const _fallbackZoom = 5.0;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng? _userLocation;
  bool _hasCenteredOnData = false;

  // "Tìm địa điểm" (Nominatim) — khác với ô search phía trên vốn lọc
  // Observation đang có, đây là kết quả tìm địa danh THẬT để bay bản
  // đồ tới, không liên quan gì đến dữ liệu Observation.
  LatLng? _searchedLocation;
  String? _searchedLocationLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchUserLocation());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Lấy vị trí user một cách "best-effort" — không chặn hay báo lỗi ồn
  /// ào nếu thất bại, vì trên Map việc có vị trí chỉ là tiện ích thêm
  /// (định vị "Vị trí của tôi", tính khoảng cách), không bắt buộc như ở
  /// Create Observation.
  Future<void> _fetchUserLocation({bool moveCamera = true}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return;

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _userLocation = latLng);

      if (moveCamera) {
        _mapController.move(latLng, 14);
      }
    } catch (_) {
      // Nuốt lỗi có chủ đích — xem docstring ở trên.
    }
  }

  void _centerOnDataIfNeeded(List<ObservationModel> observations) {
    if (_hasCenteredOnData || _userLocation != null || observations.isEmpty) {
      return;
    }
    _hasCenteredOnData = true;

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
              if (_userLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _userLocation!,
                    width: 22,
                    height: 22,
                    child: const _UserLocationDot(),
                  ),
                ]),
              if (_searchedLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _searchedLocation!,
                    width: 36,
                    height: 36,
                    child: const _SearchedLocationPin(),
                  ),
                ]),
            ],
          ),

          // Attribution bắt buộc theo license OpenStreetMap (ODbL).
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white.withOpacity(0.75),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: Colors.black87),
              ),
            ),
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
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  backgroundColor: AppColors.surfaceLight,
                  foregroundColor: AppColors.primaryDark,
                  onPressed: () => _fetchUserLocation(moveCamera: true),
                  child: const Icon(Icons.my_location),
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
