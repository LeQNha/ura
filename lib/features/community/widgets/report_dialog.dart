import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/report_model.dart';
import '../repositories/community_repository.dart';

/// Mở dialog chọn lý do report — trả về `true` nếu đã gửi báo cáo
/// thành công (để View gọi có thể hiện SnackBar xác nhận).
Future<bool> showReportDialog(
  BuildContext context, {
  required WidgetRef ref,
  required String observationId,
  required String observationTitle,
}) async {
  final selectedReason = await showDialog<String>(
    context: context,
    builder: (ctx) => _ReportReasonDialog(),
  );

  if (selectedReason == null) return false;

  final currentUser = ref.read(currentUserProvider).valueOrNull;
  if (currentUser == null) return false;

  try {
    await ref.read(communityRepositoryProvider).reportObservation(
          observationId: observationId,
          observationTitle: observationTitle,
          reporter: currentUser,
          reason: selectedReason,
        );
    return true;
  } catch (_) {
    return false;
  }
}

class _ReportReasonDialog extends StatefulWidget {
  @override
  State<_ReportReasonDialog> createState() => _ReportReasonDialogState();
}

class _ReportReasonDialogState extends State<_ReportReasonDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Báo cáo Observation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ReportReason.options.map((reason) {
          return RadioListTile<String>(
            value: reason,
            groupValue: _selected,
            title: Text(reason, style: const TextStyle(fontSize: 14)),
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(() => _selected = value),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed:
              _selected == null ? null : () => Navigator.pop(context, _selected),
          child: const Text('Gửi báo cáo', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}
