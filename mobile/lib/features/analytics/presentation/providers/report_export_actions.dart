import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/analytics_repository.dart';

final reportExportActionsProvider = Provider<ReportExportActions>(
  (ref) => ReportExportActions(ref),
);

const _extensions = <String, String>{
  'pdf': 'pdf',
  'excel': 'xlsx',
  'csv': 'csv',
};

/// §5.2 "export the resulting list" — exports exactly the same filtered
/// dataset already shown on screen (the caller passes its current filter
/// query params through unchanged), then saves the returned bytes to the
/// device via `path_provider`, the same real, already-approved technique
/// `DocumentActions.saveToDevice()` established in Sprint 15 — reused here
/// for a distinct entity (a report export, not a document), not literally
/// duplicated.
class ReportExportActions {
  final Ref _ref;

  const ReportExportActions(this._ref);

  AnalyticsRepository get _repository => _ref.read(analyticsRepositoryProvider);

  Future<String> export({
    required String reportType,
    required String format,
    Map<String, dynamic> filters = const {},
  }) async {
    final bytes = await _repository.exportReport(
      reportType: reportType,
      format: format,
      filters: filters,
    );
    final extension = _extensions[format] ?? format;
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$reportType.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
