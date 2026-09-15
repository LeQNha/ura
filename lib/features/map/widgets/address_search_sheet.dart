import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/nominatim_service.dart';
import '../../../core/theme/app_colors.dart';

/// Mở bottom sheet tìm địa điểm (forward geocoding qua Nominatim) —
/// tách riêng hoàn toàn khỏi MapSearchBar (vốn tìm trong Observation),
/// vì đây là loại tìm kiếm khác bản chất: kết quả là 1 danh sách gợi ý
/// địa điểm THẬT để bay bản đồ tới, không phải lọc marker đang hiển thị.
Future<void> showAddressSearchSheet(
  BuildContext context, {
  required void Function(NominatimPlace place) onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AddressSearchSheet(onSelected: onSelected),
  );
}

class _AddressSearchSheet extends ConsumerStatefulWidget {
  final void Function(NominatimPlace place) onSelected;

  const _AddressSearchSheet({required this.onSelected});

  @override
  ConsumerState<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends ConsumerState<_AddressSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<NominatimPlace> _results = [];
  bool _loading = false;
  bool _searchedOnce = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();

    if (value.trim().length < 3) {
      setState(() {
        _results = [];
        _loading = false;
        _searchedOnce = false;
      });
      return;
    }

    // Debounce 600ms — đợi user ngừng gõ mới gọi Nominatim, tôn trọng
    // giới hạn ~1 request/giây của họ (xem giải thích trong
    // nominatim_service.dart).
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final service = ref.read(nominatimServiceProvider);
    final results = await service.search(query);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
        _searchedOnce = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAD7D0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Tìm địa điểm', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Nhập tên đường, địa danh...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_searchedOnce && _results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Không tìm thấy địa điểm phù hợp.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.place_outlined,
                            color: AppColors.primary),
                        title: Text(
                          place.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSelected(place);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
