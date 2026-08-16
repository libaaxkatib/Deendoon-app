import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/documents/domain/document_event.dart';
import 'package:mobile/features/documents/domain/document_page.dart';
import 'package:mobile/features/documents/domain/storage_usage.dart';

Map<String, dynamic> _documentJson({
  String documentType = 'invoice',
  int? fileSize = 2048,
}) => {
  'id': '01DOC',
  'document_type': documentType,
  'reference_number': 'INV-000123',
  'generated_at': '2026-07-20T10:00:00.000000Z',
  'file_size': fileSize,
};

void main() {
  group('DocumentSummary', () {
    test('parses the common shape shared by all four document resources', () {
      final document = DocumentSummary.fromJson(_documentJson());

      expect(document.id, '01DOC');
      expect(document.documentType, 'invoice');
      expect(document.referenceNumber, 'INV-000123');
      expect(document.generatedAt, '2026-07-20T10:00:00.000000Z');
      expect(document.fileSize, 2048);
    });

    test('parses a null file_size', () {
      final document = DocumentSummary.fromJson(_documentJson(fileSize: null));

      expect(document.fileSize, isNull);
    });
  });

  group('DocumentPage', () {
    test('parses the documents + pagination envelope from GET /documents', () {
      final page = DocumentPage.fromJson({
        'documents': [_documentJson()],
        'pagination': {
          'current_page': 1,
          'per_page': 15,
          'total': 42,
          'last_page': 3,
        },
      });

      expect(page.documents, hasLength(1));
      expect(page.currentPage, 1);
      expect(page.lastPage, 3);
      expect(page.total, 42);
    });
  });

  group('StorageUsage', () {
    test('parses used_bytes, total_bytes, and used_percentage', () {
      final usage = StorageUsage.fromJson({
        'used_bytes': 5242880,
        'total_bytes': 10737418240,
        'used_percentage': 0.05,
      });

      expect(usage.usedBytes, 5242880);
      expect(usage.totalBytes, 10737418240);
      expect(usage.usedPercentage, 0.05);
    });
  });

  group('DocumentEvent', () {
    test('parses the exact DocumentEventResource shape', () {
      final event = DocumentEvent.fromJson({
        'id': '01EVT',
        'document_type': 'invoice',
        'document_id': '01DOC',
        'event_type': 'downloaded',
        'user_id': '01USER',
        'occurred_at': '2026-07-28T10:00:00.000000Z',
      });

      expect(event.id, '01EVT');
      expect(event.documentType, 'invoice');
      expect(event.documentId, '01DOC');
      expect(event.eventType, 'downloaded');
      expect(event.userId, '01USER');
    });

    test('parses a null user_id', () {
      final event = DocumentEvent.fromJson({
        'id': '01EVT',
        'document_type': 'invoice',
        'document_id': '01DOC',
        'event_type': 'generated',
        'user_id': null,
        'occurred_at': '2026-07-28T10:00:00.000000Z',
      });

      expect(event.userId, isNull);
    });
  });
}
