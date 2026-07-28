/// The one common shape shared by `ReceiptResource`, `DemandLetterResource`,
/// `StatementResource`, and `InvoiceResource` — every entry `GET
/// /debts/{id}/documents` returns, regardless of underlying document type.
class DebtDocument {
  final String id;
  final String documentType;
  final String referenceNumber;
  final String generatedAt;
  final int? fileSize;

  const DebtDocument({
    required this.id,
    required this.documentType,
    required this.referenceNumber,
    required this.generatedAt,
    required this.fileSize,
  });

  factory DebtDocument.fromJson(Map<String, dynamic> json) => DebtDocument(
        id: json['id'].toString(),
        documentType: json['document_type'] as String,
        referenceNumber: json['reference_number'] as String,
        generatedAt: json['generated_at'] as String,
        fileSize: json['file_size'] as int?,
      );
}
