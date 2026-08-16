import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_request_page.dart';
import 'package:mobile/features/professional_collection/domain/professional_collection_summary.dart';
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
      'reasons': ['Repeated missed promises'],
      'notes': 'Customer stopped responding.',
      'requested_services': ['Field Visit'],
      'declaration_accepted_at': '2026-08-01T00:00:00.000000Z',
      'declaration_accepted_by': '01USER',
      'created_at': '2026-08-01T00:00:00.000000Z',
      'closed_at': null,
    });

    expect(request.id, '1');
    expect(request.collectionCaseId, '01CASE');
    expect(request.referenceNumber, 'PCR-0001');
    expect(request.status, 'submitted');
    expect(request.submittedByUserId, '01USER');
    expect(request.actionedByUserId, isNull);
    expect(request.reasons, ['Repeated missed promises']);
    expect(request.notes, 'Customer stopped responding.');
    expect(request.requestedServices, ['Field Visit']);
    expect(request.declarationAcceptedAt, '2026-08-01T00:00:00.000000Z');
    expect(request.declarationAcceptedBy, '01USER');
    expect(request.closedAt, isNull);
    expect(request.isTerminal, isFalse);
  });

  test(
    'ProfessionalCollectionRequest defaults reasons/requestedServices to empty when absent',
    () {
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

      expect(request.reasons, isEmpty);
      expect(request.requestedServices, isEmpty);
      expect(request.notes, isNull);
      expect(request.declarationAcceptedAt, isNull);
      expect(request.declarationAcceptedBy, isNull);
    },
  );

  test(
    'ProfessionalCollectionRequest.isTerminal is true for recovered and closed',
    () {
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
    },
  );

  test(
    'ProfessionalCollectionRequestPage parses the requests + pagination envelope',
    () {
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
        'pagination': {
          'current_page': 1,
          'per_page': 20,
          'total': 1,
          'last_page': 1,
        },
      });

      expect(page.requests, hasLength(1));
      expect(page.currentPage, 1);
      expect(page.lastPage, 1);
      expect(page.total, 1);
    },
  );

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

  test(
    'ProfessionalCollectionSummary parses the exact summary() shape, including a null latest_request',
    () {
      final summary = ProfessionalCollectionSummary.fromJson({
        'counts_by_status': {
          'submitted': 0,
          'under_review': 0,
          'need_more_information': 0,
          'accepted': 0,
          'assigned': 0,
          'in_progress': 0,
          'recovered': 0,
          'closed': 0,
        },
        'total_active': 0,
        'total_recovered': 0,
        'latest_request': null,
        'latest_timeline_event': null,
      });

      expect(summary.countsByStatus['submitted'], 0);
      expect(summary.totalActive, 0);
      expect(summary.totalRecovered, 0);
      expect(summary.latestRequest, isNull);
      expect(summary.latestTimelineEvent, isNull);
      expect(summary.isEmpty, isTrue);
    },
  );

  test(
    'ProfessionalCollectionSummary parses a real latest_request and latest_timeline_event',
    () {
      final summary = ProfessionalCollectionSummary.fromJson({
        'counts_by_status': {
          'submitted': 1,
          'under_review': 0,
          'need_more_information': 0,
          'accepted': 0,
          'assigned': 1,
          'in_progress': 0,
          'recovered': 2,
          'closed': 0,
        },
        'total_active': 2,
        'total_recovered': 2,
        'latest_request': {
          'id': '01PCR',
          'collection_case_id': '01CASE',
          'reference_number': 'PCR-0003',
          'status': 'assigned',
          'submitted_by_user_id': '01USER',
          'actioned_by_user_id': '02USER',
          'created_at': '2026-08-03T00:00:00.000000Z',
          'closed_at': null,
        },
        'latest_timeline_event': {
          'id': '1',
          'professional_collection_request_id': '01PCR',
          'event_type': 'field_visit',
          'officer_user_id': '02USER',
          'occurred_at': '2026-08-03T00:00:00.000000Z',
          'notes': null,
          'outcome': null,
          'created_at': '2026-08-03T00:00:00.000000Z',
          'updated_at': '2026-08-03T00:00:00.000000Z',
        },
      });

      expect(summary.totalActive, 2);
      expect(summary.totalRecovered, 2);
      expect(summary.latestRequest?.referenceNumber, 'PCR-0003');
      expect(summary.latestTimelineEvent?.eventType, 'field_visit');
      expect(summary.isEmpty, isFalse);
    },
  );
}
