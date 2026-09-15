import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/directions_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/directions_button.dart';
import '../../map/viewmodels/map_viewmodel.dart';
import '../../observation/models/category_model.dart';
import '../../observation/services/category_service.dart';
import '../models/trip_plan.dart';
import '../utils/trip_planning.dart';
import '../widgets/trip_route_preview.dart';

const _timeBudgetOptions = [30, 60, 120, 180]; // phút

/// Trip Planning ("Discovery Route") — mở qua Navigator.push trực
/// tiếp (không cần route riêng trong go_router, không cần tham số
/// đường dẫn), giống cách ThenAndNowPage/EditObservationPage đã làm.
class TripPlannerPage extends ConsumerStatefulWidget {
  const TripPlannerPage({super.key});

  @override
  ConsumerState<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends ConsumerState<TripPlannerPage> {
  int _selectedMinutes = 60;
  final Set<String> _selectedCategoryIds = {};
  bool _isPlanning = false;
  String? _error;

  TripPlan? _plan;
  LatLng? _startLocation;

  Future<void> _handleCreateTrip() async {
    setState(() {
      _isPlanning = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Vui lòng bật GPS/Dịch vụ vị trí.';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Bạn cần cấp quyền vị trí để lập kế hoạch chuyến đi.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final start = LatLng(position.latitude, position.longitude);

      final candidates = ref.read(mapObservationsProvider).valueOrNull ?? [];
      if (candidates.isEmpty) {
        throw 'Chưa có Observation nào quanh đây để lập kế hoạch.';
      }

      final plan = planTrip(
        start: start,
        candidates: candidates,
        timeBudget: Duration(minutes: _selectedMinutes),
        preferredCategoryIds: _selectedCategoryIds,
      );

      if (plan.isEmpty) {
        throw 'Không tìm được lộ trình phù hợp trong thời gian này. '
            'Thử tăng thời gian hoặc bỏ bớt bộ lọc danh mục.';
      }

      if (mounted) {
        setState(() {
          _startLocation = start;
          _plan = plan;
          _isPlanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlanning = false;
          _error = e.toString();
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _plan = null;
      _startLocation = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Giữ mapObservationsProvider "sống" trong lúc màn này mở, để lúc
    // bấm "Tạo lộ trình" luôn có dữ liệu sẵn sàng thay vì phải tự chờ
    // fetch từ đầu.
    ref.watch(mapObservationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lên kế hoạch khám phá')),
      body: _plan == null ? _buildForm(context) : _buildResult(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.route_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cho biết bạn có bao nhiêu thời gian, app sẽ tự gợi ý '
                  'một lộ trình khám phá khép kín gần bạn.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Bạn có bao nhiêu thời gian?',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _timeBudgetOptions.map((minutes) {
            final selected = _selectedMinutes == minutes;
            final label = minutes < 60
                ? '$minutes phút'
                : '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} giờ';
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => setState(() => _selectedMinutes = minutes),
              selectedColor: AppColors.primary.withOpacity(0.18),
              labelStyle: TextStyle(
                color: selected ? AppColors.primaryDark : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Ưu tiên danh mục nào? (tùy chọn)',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Không chọn gì = xem xét tất cả danh mục như nhau.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((c) {
              final selected = _selectedCategoryIds.contains(c.id);
              return FilterChip(
                label: Text('${c.icon} ${c.name}'),
                selected: selected,
                onSelected: (value) => setState(() {
                  if (value) {
                    _selectedCategoryIds.add(c.id);
                  } else {
                    _selectedCategoryIds.remove(c.id);
                  }
                }),
                selectedColor: AppColors.primary.withOpacity(0.18),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primaryDark : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Lỗi tải danh mục: $e'),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isPlanning ? null : _handleCreateTrip,
            icon: _isPlanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: const Text('Tạo lộ trình'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final plan = _plan!;
    final start = _startLocation!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TripRoutePreview(start: start, plan: plan),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.place_outlined,
                  value: '${plan.stops.length}',
                  label: 'Điểm dừng',
                ),
              ),
              Container(width: 1, height: 36, color: Theme.of(context).dividerColor),
              Expanded(
                child: _StatItem(
                  icon: Icons.route_outlined,
                  value: formatDistance(plan.totalDistanceMeters),
                  label: 'Quãng đường',
                ),
              ),
              Container(width: 1, height: 36, color: Theme.of(context).dividerColor),
              Expanded(
                child: _StatItem(
                  icon: Icons.timer_outlined,
                  value: formatDuration(plan.estimatedTotalDuration),
                  label: 'Thời gian',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => openMultiStopDirections(
              context,
              originLat: start.latitude,
              originLng: start.longitude,
              stops: plan.stops
                  .map((s) => (
                        latitude: s.observation.latitude,
                        longitude: s.observation.longitude,
                      ))
                  .toList(),
            ),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Mở toàn bộ lộ trình trên Google Maps'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _reset,
            child: const Text('Lập lộ trình khác'),
          ),
        ),
        const SizedBox(height: 24),
        Text('Các điểm dừng', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < plan.stops.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TripStopTile(index: i + 1, stop: plan.stops[i]),
          ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _TripStopTile extends StatelessWidget {
  final int index;
  final TripStop stop;

  const _TripStopTile({required this.index, required this.stop});

  @override
  Widget build(BuildContext context) {
    final observation = stop.observation;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${observation.categoryIcon} ${observation.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cách điểm trước ${formatDistance(stop.distanceFromPreviousMeters)} '
                  '· ~${formatDuration(stop.walkingTimeFromPrevious)} đi bộ',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          DirectionsButton(
            latitude: observation.latitude,
            longitude: observation.longitude,
            compact: true,
          ),
        ],
      ),
    );
  }
}
