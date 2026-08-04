/// One row of `CustomerImportController::commit`'s response — mirrors
/// `processRow()`'s return value exactly. `outcome` is one of
/// `created`, `updated`, `skipped`, `skipped_invalid` — never any other
/// value, since those are the only four the backend ever returns.
class ImportResultRow {
  final int rowNumber;
  final String outcome;
  final String? customerId;

  const ImportResultRow({required this.rowNumber, required this.outcome, required this.customerId});

  factory ImportResultRow.fromJson(Map<String, dynamic> json) => ImportResultRow(
        rowNumber: json['row_number'] as int,
        outcome: json['outcome'] as String,
        customerId: json['customer_id']?.toString(),
      );
}

/// Mirrors `CustomerImportController::commit`'s response: the `data`
/// envelope (`{batch_id, status, results}`) plus the envelope's own
/// top-level `message` (`App\Traits\ApiResponse::successResponse`'s
/// second argument, e.g. "Import committed successfully") — the real
/// backend response message the sprint asks to display, not a fabricated
/// one.
class ImportCommitResult {
  final String batchId;
  final String status;
  final List<ImportResultRow> results;
  final String message;

  const ImportCommitResult({
    required this.batchId,
    required this.status,
    required this.results,
    required this.message,
  });

  factory ImportCommitResult.fromJson(Map<String, dynamic> json) => ImportCommitResult(
        batchId: json['batch_id'].toString(),
        status: json['status'] as String,
        results: (json['results'] as List<dynamic>)
            .map((e) => ImportResultRow.fromJson(e as Map<String, dynamic>))
            .toList(),
        message: json['message'] as String? ?? '',
      );
}
