/// The one common shape shared by `ReceiptResource`, `DemandLetterResource`,
/// `StatementResource`, and `InvoiceResource` — every entry `GET
/// /debts/{id}/documents`, `GET /customers/{id}/documents`, the tenant-wide
/// `GET /documents`, and `GET /documents/{id}` return, regardless of
/// underlying document type. Promoted from the Debts feature (Sprint 12)
/// to `core/models/` in Sprint 15 once the Documents Center needed the
/// identical shape tenant-wide — same reuse rationale as `Payment`.
class DocumentSummary {
  final String id;
  final String documentType;
  final String referenceNumber;
  final String generatedAt;
  final int? fileSize;

  const DocumentSummary({
    required this.id,
    required this.documentType,
    required this.referenceNumber,
    required this.generatedAt,
    required this.fileSize,
  });

  factory DocumentSummary.fromJson(Map<String, dynamic> json) =>
      DocumentSummary(
        id: json['id'].toString(),
        documentType: json['document_type'] as String,
        referenceNumber: json['reference_number'] as String,
        generatedAt: json['generated_at'] as String,
        fileSize: json['file_size'] as int?,
      );
}
