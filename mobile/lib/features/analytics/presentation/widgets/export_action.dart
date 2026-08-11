import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
  final l10n = AppLocalizations.of(context);

  final format = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.exportActionSheetTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          ListTile(title: Text(l10n.exportFormatPdf), onTap: () => Navigator.pop(context, 'pdf')),
          ListTile(title: Text(l10n.exportFormatExcel), onTap: () => Navigator.pop(context, 'excel')),
          ListTile(title: Text(l10n.exportFormatCsv), onTap: () => Navigator.pop(context, 'csv')),
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
    messenger.showSnackBar(SnackBar(content: Text(l10n.exportSavedToPathMessage(path))));
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
