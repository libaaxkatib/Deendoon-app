import 'import_preview_row.dart';

/// Mirrors `CustomerImportController::store`'s top-level response shape:
/// `{batch_id, status, rows}`.
class ImportPreview {
  final String batchId;
  final String status;
  final List<ImportPreviewRow> rows;

  const ImportPreview({required this.batchId, required this.status, required this.rows});

  factory ImportPreview.fromJson(Map<String, dynamic> json) => ImportPreview(
        batchId: json['batch_id'].toString(),
        status: json['status'] as String,
        rows: (json['rows'] as List<dynamic>)
            .map((e) => ImportPreviewRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
