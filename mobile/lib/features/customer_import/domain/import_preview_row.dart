/// One row of `CustomerImportController::store`'s preview response —
/// mirrors `rowToArray()` exactly. Nothing is created yet at this stage;
/// this is Preview only (FR-016 Main Flow steps 1-4).
class ImportDuplicateMatch {
  final String customerId;
  final String name;

  const ImportDuplicateMatch({required this.customerId, required this.name});

  factory ImportDuplicateMatch.fromJson(Map<String, dynamic> json) => ImportDuplicateMatch(
        customerId: json['customer_id'].toString(),
        name: json['name'] as String,
      );
}

class ImportPreviewRow {
  final int rowNumber;
  final Map<String, dynamic> data;
  final String validationStatus;
  final List<String>? validationErrors;
  final ImportDuplicateMatch? duplicateMatch;

  const ImportPreviewRow({
    required this.rowNumber,
    required this.data,
    required this.validationStatus,
    required this.validationErrors,
    required this.duplicateMatch,
  });

  bool get isValid => validationStatus == 'valid';

  factory ImportPreviewRow.fromJson(Map<String, dynamic> json) => ImportPreviewRow(
        rowNumber: json['row_number'] as int,
        data: json['data'] as Map<String, dynamic>,
        validationStatus: json['validation_status'] as String,
        validationErrors: (json['validation_errors'] as List<dynamic>?)?.map((e) => e as String).toList(),
        duplicateMatch: json['duplicate_match'] != null
            ? ImportDuplicateMatch.fromJson(json['duplicate_match'] as Map<String, dynamic>)
            : null,
      );
}
