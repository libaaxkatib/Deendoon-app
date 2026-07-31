import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../providers/report_export_actions.dart';

/// §5.2 "export the resulting list" — shared across every Reports
/// category screen. Exports exactly the filters currently applied on
/// screen (passed in by the caller), never a different, unfiltered
/// dataset.
Future<void> showExportSheet(
  BuildContext context,
  WidgetRef ref, {
  required String reportType,
  required Map<String, dynamic> filters,
}) async {
  final format = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Export as', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ListTile(title: const Text('PDF'), onTap: () => Navigator.pop(context, 'pdf')),
          ListTile(title: const Text('Excel'), onTap: () => Navigator.pop(context, 'excel')),
          ListTile(title: const Text('CSV'), onTap: () => Navigator.pop(context, 'csv')),
        ],
      ),
    ),
  );

  if (format == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final path = await ref
        .read(reportExportActionsProvider)
        .export(reportType: reportType, format: format, filters: filters);
    messenger.showSnackBar(SnackBar(content: Text('Saved to $path')));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
