import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/attachments/domain/attachment.dart';

void main() {
  group('Attachment', () {
    test('parses a CustomerAttachmentResource shape (customer_id)', () {
      final attachment = Attachment.fromJson({
        'id': '1',
        'customer_id': '01CUST',
        'uploaded_by_user_id': '01USER',
        'original_filename': 'id-card.pdf',
        'mime_type': 'application/pdf',
        'file_size': 2000,
        'description': 'ID card',
        'created_at': '2026-08-01T00:00:00.000000Z',
      });

      expect(attachment.id, '1');
      expect(attachment.entityId, '01CUST');
      expect(attachment.uploadedByUserId, '01USER');
      expect(attachment.originalFilename, 'id-card.pdf');
      expect(attachment.mimeType, 'application/pdf');
      expect(attachment.fileSize, 2000);
      expect(attachment.description, 'ID card');
    });

    test('parses a DebtAttachmentResource shape (debt_id)', () {
      final attachment = Attachment.fromJson({
        'id': '1',
        'debt_id': '01DEBT',
        'uploaded_by_user_id': null,
        'original_filename': 'invoice-scan.jpg',
        'mime_type': 'image/jpeg',
        'file_size': 1500,
        'description': null,
        'created_at': '2026-08-01T00:00:00.000000Z',
      });

      expect(attachment.entityId, '01DEBT');
      expect(attachment.uploadedByUserId, isNull);
      expect(attachment.description, isNull);
    });

    test(
      'parses a CollectionCaseAttachmentResource shape (collection_case_id)',
      () {
        final attachment = Attachment.fromJson({
          'id': '1',
          'collection_case_id': '01CASE',
          'uploaded_by_user_id': '01USER',
          'original_filename': 'evidence.pdf',
          'mime_type': 'application/pdf',
          'file_size': 3000,
          'description': null,
          'created_at': '2026-08-01T00:00:00.000000Z',
        });

        expect(attachment.entityId, '01CASE');
        expect(attachment.originalFilename, 'evidence.pdf');
      },
    );
  });
}
