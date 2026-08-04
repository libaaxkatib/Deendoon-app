import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/customer_import/domain/import_commit_result.dart';
import 'package:mobile/features/customer_import/domain/import_preview.dart';
import 'package:mobile/features/customer_import/domain/import_preview_row.dart';

void main() {
  group('ImportPreviewRow', () {
    test('parses a valid row with no duplicate match', () {
      final row = ImportPreviewRow.fromJson({
        'row_number': 1,
        'data': {'name': 'Jane Trader', 'phone': '254711111111', 'credit_limit': 1000},
        'validation_status': 'valid',
        'validation_errors': null,
        'duplicate_match': null,
      });

      expect(row.rowNumber, 1);
      expect(row.isValid, isTrue);
      expect(row.validationErrors, isNull);
      expect(row.duplicateMatch, isNull);
    });

    test('parses an invalid row with real validation errors', () {
      final row = ImportPreviewRow.fromJson({
        'row_number': 2,
        'data': {'name': '', 'phone': '254711111111', 'credit_limit': null},
        'validation_status': 'invalid',
        'validation_errors': ['name is required', 'credit_limit is required and must be a non-negative number'],
        'duplicate_match': null,
      });

      expect(row.isValid, isFalse);
      expect(row.validationErrors, hasLength(2));
    });

    test('parses a row with a real duplicate match', () {
      final row = ImportPreviewRow.fromJson({
        'row_number': 3,
        'data': {'name': 'Existing Person', 'phone': '254711111111', 'credit_limit': 900},
        'validation_status': 'valid',
        'validation_errors': null,
        'duplicate_match': {'customer_id': '01CUST', 'name': 'Existing Person'},
      });

      expect(row.duplicateMatch, isNotNull);
      expect(row.duplicateMatch!.customerId, '01CUST');
    });
  });

  group('ImportPreview', () {
    test('parses the batch_id/status/rows envelope from POST /customers/import', () {
      final preview = ImportPreview.fromJson({
        'batch_id': '01BATCH',
        'status': 'preview',
        'rows': [
          {
            'row_number': 1,
            'data': {'name': 'Jane Trader', 'phone': '254711111111', 'credit_limit': 1000},
            'validation_status': 'valid',
            'validation_errors': null,
            'duplicate_match': null,
          },
        ],
      });

      expect(preview.batchId, '01BATCH');
      expect(preview.status, 'preview');
      expect(preview.rows, hasLength(1));
    });
  });

  group('ImportCommitResult', () {
    test('parses the batch_id/status/results envelope plus the top-level message', () {
      final result = ImportCommitResult.fromJson({
        'batch_id': '01BATCH',
        'status': 'committed',
        'results': [
          {'row_number': 1, 'outcome': 'created', 'customer_id': '01CUST'},
          {'row_number': 2, 'outcome': 'skipped', 'customer_id': null},
        ],
        'message': 'Import committed successfully',
      });

      expect(result.status, 'committed');
      expect(result.results, hasLength(2));
      expect(result.results.first.outcome, 'created');
      expect(result.results.first.customerId, '01CUST');
      expect(result.results.last.customerId, isNull);
      expect(result.message, 'Import committed successfully');
    });

    test('defaults message to an empty string when absent', () {
      final result = ImportCommitResult.fromJson({'batch_id': '01BATCH', 'status': 'committed', 'results': []});

      expect(result.message, '');
      expect(result.results, isEmpty);
    });
  });
}
