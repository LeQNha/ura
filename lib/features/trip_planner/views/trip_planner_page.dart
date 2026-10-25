import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/directions_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../map/viewmodels/map_viewmodel.dart';
import '../../observation/services/category_service.dart';
import '../models/route_preferences.dart';
import '../utils/personalized_route_mapper.dart';
import '../viewmodels/personalized_trip_viewmodel.dart';
import '../widgets/route_insight_widgets.dart';
import '../widgets/trip_route_preview.dart';

const _timeBudgetOptions = [30, 60, 120, 180]; // phút
const _maxStopsOptions = [3, 4, 6, 8];

String _timeLabel(int minutes) {
  if (minutes < 60) return '$minutes phút';
  return '${(minutes / 60).toStringAsFixed(minutes % 60 == 0 ? 0 : 1)} giờ';
}

/// Lên kế hoạch khám phá — lộ trình CÁ NHÂN HÓA do AI lập.
///
/// Mở qua Navigator.push trực tiếp (không cần route riêng trong
/// go_router, không cần tham số đường dẫn), giống cách ThenAndNowPage/
/// EditObservationPage đã làm.
///
/// Toàn bộ trạng thái và logic nằm ở [PersonalizedTripViewModel]; màn
/// hình chỉ hiển thị: form yêu cầu khi chưa có kết quả, và kết quả (kèm
/// hồ sơ sở thích + lý do từng điểm) khi đã có.
class TripPlannerPage extends ConsumerWidget {
  const TripPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Giữ mapObservationsProvider "sống" trong lúc màn này mở, để lúc
    // bấm "Tạo lộ trình" luôn có dữ liệu sẵn sàng thay vì phải tự chờ
    // fetch từ đầu.
    ref.watch(mapObservationsProvider);
    final state = ref.watch(personalizedTripViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lên kế hoạch khám phá')),
      body:
          state.hasResult ? _ResultView(state: state) : _FormView(state: state),
    );
  }
}

// ---------------------------------------------------------------------
// FORM
// ---------------------------------------------------------------------
class _FormView extends ConsumerWidget {
  final PersonalizedTripState state;

  const _FormView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(personalizedTripViewModelProvider.notifier);
    final prefs = state.preferences;
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final observations = ref.watch(mapObservationsProvider).valueOrNull ?? [];
    final tagSuggestions = suggestTags(observations);
    final theme = Theme.of(context);

    void update(RoutePreferences next) => notifier.setPreferences(next);

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
              const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cho AI biết thời gian và sở thích của bạn, AI sẽ chọn và '
                  'sắp xếp các điểm dừng sao cho hợp gu nhất trong thời gian '
                  'đó. AI cũng học từ các bài bạn đã đăng và đã lưu.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ---- Thời gian ----
        _SectionTitle('Bạn có bao nhiêu thời gian?'),
        const SizedBox(height: 8),
        _OptionChips<int>(
          values: _timeBudgetOptions,
          selected: prefs.timeBudgetMinutes,
          labelOf: _timeLabel,
          onSelected: (v) => update(prefs.copyWith(timeBudgetMinutes: v)),
        ),
        const SizedBox(height: 24),

        // ---- Nhịp đi bộ ----
        _SectionTitle('Nhịp đi bộ của bạn'),
        const SizedBox(height: 8),
        _OptionChips<WalkingPace>(
          values: WalkingPace.values,
          selected: prefs.pace,
          labelOf: (p) => '${p.label} (${p.speedKmh} km/h)',
          onSelected: (v) => update(prefs.copyWith(pace: v)),
        ),
        const SizedBox(height: 24),

        // ---- Số điểm dừng ----
        _SectionTitle('Tối đa bao nhiêu điểm dừng?'),
        const SizedBox(height: 8),
        _OptionChips<int>(
          values: _maxStopsOptions,
          selected: prefs.maxStops,
          labelOf: (v) => '$v điểm',
          onSelected: (v) => update(prefs.copyWith(maxStops: v)),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Quay về điểm xuất phát'),
          subtitle: const Text('Tắt nếu bạn muốn kết thúc ở điểm dừng cuối.'),
          value: prefs.roundTrip,
          onChanged: (v) => update(prefs.copyWith(roundTrip: v)),
        ),
        const SizedBox(height: 16),

        // ---- Chủ đề ----
        _SectionTitle(
          'Bạn thích chủ đề nào? (tùy chọn)',
          subtitle: 'Không chọn gì: AI tự suy ra từ các bài bạn đã đăng/lưu.',
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((c) {
              final selected = prefs.categoryIds.contains(c.id);
              return FilterChip(
                label: Text('${c.icon} ${c.name}'),
                selected: selected,
                onSelected: (value) {
                  final next = {...prefs.categoryIds};
                  if (value) {
                    next.add(c.id);
                  } else {
                    next.remove(c.id);
                  }
                  update(prefs.copyWith(categoryIds: next));
                },
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

        // ---- Thẻ gợi ý ----
        if (tagSuggestions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle(
            'Thẻ bạn quan tâm (tùy chọn)',
            subtitle: 'Các thẻ phổ biến quanh đây.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagSuggestions.map((tag) {
              final selected = prefs.tags.contains(tag);
              return FilterChip(
                label: Text('#$tag'),
                selected: selected,
                onSelected: (value) {
                  final next = {...prefs.tags};
                  if (value) {
                    next.add(tag);
                  } else {
                    next.remove(tag);
                  }
                  update(prefs.copyWith(tags: next));
                },
                selectedColor: AppColors.primary.withOpacity(0.18),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primaryDark : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 24),

        // ---- Độ hiếm ----
        _SectionTitle('Độ hiếm ưa thích'),
        const SizedBox(height: 8),
        _OptionChips<RarityPreference>(
          values: RarityPreference.values,
          selected: prefs.rarity,
          labelOf: (r) => r.label,
          onSelected: (v) => update(prefs.copyWith(rarity: v)),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ưu tiên chỗ bạn chưa ghi nhận'),
          subtitle: const Text('Tránh lặp lại những nơi bạn đã đăng.'),
          value: prefs.preferNewPlaces,
          onChanged: (v) => update(prefs.copyWith(preferNewPlaces: v)),
        ),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: state.isPlanning ? null : () => notifier.generate(),
            icon: state.isPlanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
                state.isPlanning ? 'AI đang lập lộ trình...' : 'Tạo lộ trình'),
          ),
        ),
        if (state.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------
// KẾT QUẢ
// ---------------------------------------------------------------------
class _ResultView extends ConsumerWidget {
  final PersonalizedTripState state;

  const _ResultView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = state.plan!;
    final start = state.start!;
    final ai = state.ai;
    final theme = Theme.of(context);

    final stats = <({IconData icon, String value, String label})>[
      (
        icon: Icons.place_outlined,
        value: '${plan.stops.length}',
        label: 'Điểm dừng',
      ),
      (
        icon: Icons.route_outlined,
        value: formatDistance(plan.totalDistanceMeters),
        label: 'Quãng đường',
      ),
      (
        icon: Icons.timer_outlined,
        value: formatDuration(plan.estimatedTotalDuration),
        label: 'Thời gian',
      ),
      if (ai != null)
        (
          icon: Icons.favorite_outline,
          value: '${ai.route.avgMatchPercent}%',
          label: 'Hợp gu TB',
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AiSourceBadge(personalized: ai != null),
        ),
        if (state.notice != null) ...[
          const SizedBox(height: 10),
          RouteNoticeBanner(message: state.notice!),
        ],
        const SizedBox(height: 12),
        TripRoutePreview(start: start, plan: plan),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0)
                  Container(width: 1, height: 36, color: theme.dividerColor),
                Expanded(
                  child: _StatItem(
                    icon: stats[i].icon,
                    value: stats[i].value,
                    label: stats[i].label,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (ai != null) ...[
          const SizedBox(height: 16),
          TasteProfileCard(profile: ai.profile),
        ],
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
            onPressed: () =>
                ref.read(personalizedTripViewModelProvider.notifier).reset(),
            child: const Text('Lập lộ trình khác'),
          ),
        ),
        const SizedBox(height: 24),
        Text('Các điểm dừng', style: theme.textTheme.titleMedium),
        if (ai != null) ...[
          const SizedBox(height: 4),
          Text(
            'Mỗi điểm kèm lý do AI chọn nó.',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        for (var i = 0; i < plan.stops.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PersonalizedStopTile(index: i + 1, stop: plan.stops[i]),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// WIDGET NHỎ DÙNG CHUNG TRONG TRANG
// ---------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle(this.title, {this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

/// Hàng ChoiceChip chọn 1 trong nhiều giá trị.
class _OptionChips<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  const _OptionChips({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final isSelected = value == selected;
        return ChoiceChip(
          label: Text(labelOf(value)),
          selected: isSelected,
          onSelected: (_) => onSelected(value),
          selectedColor: AppColors.primary.withOpacity(0.18),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primaryDark : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem(
      {required this.icon, required this.value, required this.label});

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
