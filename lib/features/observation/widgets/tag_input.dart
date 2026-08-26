import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Input nhập Tag dạng chip — gõ rồi nhấn Enter (hoặc dấu phẩy) để
/// thêm tag, tương tự cách nhập tag quen thuộc ở nhiều app khác.
///
/// Tag ở Phase 1 là free-text do user tự gõ (theo quyết định đã thống
/// nhất: dùng array field trên Observation, KHÔNG tạo Tag entity riêng
/// để giảm độ phức tạp) — không có gợi ý/autocomplete từ tag đã tồn tại,
/// có thể bổ sung sau nếu cần.
class TagInput extends StatefulWidget {
  final List<String> tags;
  final void Function(String tag) onAdd;
  final void Function(String tag) onRemove;

  const TagInput({
    super.key,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();

  void _submit() {
    final value = _controller.text;
    if (value.trim().isNotEmpty) {
      widget.onAdd(value);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'vd: old, faded, colonial...',
            prefixIcon: Icon(Icons.tag),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          inputFormatters: [
            // Chặn dấu phẩy ngay lúc gõ, tự động thêm tag thay vì để
            // dấu phẩy lọt vào text field — trải nghiệm mượt hơn so với
            // việc parse dấu phẩy sau khi đã submit.
            TextInputFormatter.withFunction((oldValue, newValue) {
              if (newValue.text.endsWith(',')) {
                final tag = newValue.text.substring(0, newValue.text.length - 1);
                if (tag.trim().isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onAdd(tag);
                    _controller.clear();
                  });
                }
                return oldValue;
              }
              return newValue;
            }),
          ],
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text('#$tag'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => widget.onRemove(tag),
                backgroundColor: AppColors.primary.withOpacity(0.08),
                labelStyle: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                side: BorderSide.none,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
