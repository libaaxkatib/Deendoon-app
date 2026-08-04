import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request_page.dart';
import 'package:mobile/features/professional_collection/domain/request_message.dart';

void main() {
  test('ProfessionalCollectionRequest parses the exact resource shape', () {
    final request = ProfessionalCollectionRequest.fromJson({
      'id': '1',
      'collection_case_id': '01CASE',
      'reference_number': 'PCR-0001',
      'status': 'submitted',
      'submitted_by_user_id': '01USER',
      'actioned_by_user_id': null,
      'created_at': '2026-08-01T00:00:00.000000Z',
      'closed_at': null,
    });

    expect(request.id, '1');
    expect(request.collectionCaseId, '01CASE');
    expect(request.referenceNumber, 'PCR-0001');
    expect(request.status, 'submitted');
    expect(request.submittedByUserId, '01USER');
    expect(request.actionedByUserId, isNull);
    expect(request.closedAt, isNull);
    expect(request.isTerminal, isFalse);
  });

  test('ProfessionalCollectionRequest.isTerminal is true for recovered and closed', () {
    for (final status in ['recovered', 'closed']) {
      final request = ProfessionalCollectionRequest.fromJson({
        'id': '1',
        'collection_case_id': '01CASE',
        'reference_number': 'PCR-0001',
        'status': status,
        'submitted_by_user_id': '01USER',
        'actioned_by_user_id': '02USER',
        'created_at': '2026-08-01T00:00:00.000000Z',
        'closed_at': '2026-08-02T00:00:00.000000Z',
      });

      expect(request.isTerminal, isTrue, reason: 'status=$status');
    }
  });

  test('ProfessionalCollectionRequestPage parses the requests + pagination envelope', () {
    final page = ProfessionalCollectionRequestPage.fromJson({
      'professional_requests': [
        {
          'id': '1',
          'collection_case_id': '01CASE',
          'reference_number': 'PCR-0001',
          'status': 'submitted',
          'submitted_by_user_id': '01USER',
          'actioned_by_user_id': null,
          'created_at': '2026-08-01T00:00:00.000000Z',
          'closed_at': null,
        },
      ],
      'pagination': {'current_page': 1, 'per_page': 20, 'total': 1, 'last_page': 1},
    });

    expect(page.requests, hasLength(1));
    expect(page.currentPage, 1);
    expect(page.lastPage, 1);
    expect(page.total, 1);
  });

  test('RequestMessage parses the exact resource shape', () {
    final message = RequestMessage.fromJson({
      'id': '1',
      'professional_collection_request_id': '01PCR',
      'sender_user_id': '01USER',
      'content': 'Hello',
      'created_at': '2026-08-01T00:00:00.000000Z',
    });

    expect(message.id, '1');
    expect(message.professionalCollectionRequestId, '01PCR');
    expect(message.senderUserId, '01USER');
    expect(message.content, 'Hello');
  });
}
