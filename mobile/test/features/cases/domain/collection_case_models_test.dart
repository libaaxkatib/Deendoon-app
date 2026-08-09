import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cases/domain/case_history.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/domain/collection_case_page.dart';

Map<String, dynamic> _caseJson({
  String caseStatus = 'open',
  String? closureOutcome,
  String? assignedOfficerUserId,
  String? notes,
}) =>
    {
      'id': '01CASE',
      'debt_id': '01DEBT',
      'customer_id': '01CUST',
      'customer_name': 'Somali Builders',
      'outstanding_amount': '4467.40',
      'risk_level': 'high',
      'reference_number': 'COL-0001',
      'assigned_officer_user_id': assignedOfficerUserId,
      'case_status': caseStatus,
      'closure_outcome': closureOutcome,
      'notes': notes,
      'last_activity_at': '2026-07-28T10:00:00.000000Z',
      'created_at': '2026-07-01T10:00:00.000000Z',
      'closed_at': null,
    };

void main() {
  group('CollectionCase', () {
    test('parses the exact CollectionCaseResource shape', () {
      final collectionCase = CollectionCase.fromJson(_caseJson(assignedOfficerUserId: '01OFFICER'));

      expect(collectionCase.id, '01CASE');
      expect(collectionCase.debtId, '01DEBT');
      expect(collectionCase.customerId, '01CUST');
      expect(collectionCase.customerName, 'Somali Builders');
      expect(collectionCase.outstandingAmount, '4467.40');
      expect(collectionCase.riskLevel, 'high');
      expect(collectionCase.referenceNumber, 'COL-0001');
      expect(collectionCase.assignedOfficerUserId, '01OFFICER');
      expect(collectionCase.caseStatus, 'open');
      expect(collectionCase.closureOutcome, isNull);
      expect(collectionCase.notes, isNull);
      expect(collectionCase.lastActivityAt, '2026-07-28T10:00:00.000000Z');
      expect(collectionCase.closedAt, isNull);
    });

    test('parses a null assigned_officer_user_id (no officer assigned yet)', () {
      final collectionCase = CollectionCase.fromJson(_caseJson());

      expect(collectionCase.assignedOfficerUserId, isNull);
    });

    test('parses a real notes value', () {
      final collectionCase =
          CollectionCase.fromJson(_caseJson(notes: 'Called customer, promised payment next week.'));

      expect(collectionCase.notes, 'Called customer, promised payment next week.');
    });

    test('parses a closed case with a closure outcome', () {
      final collectionCase = CollectionCase.fromJson(_caseJson(caseStatus: 'closed', closureOutcome: 'Paid in full'));

      expect(collectionCase.caseStatus, 'closed');
      expect(collectionCase.closureOutcome, 'Paid in full');
    });
  });

  group('CollectionCasePage', () {
    test('parses the collection_cases + pagination envelope from GET /collection-cases', () {
      final page = CollectionCasePage.fromJson({
        'collection_cases': [_caseJson()],
        'pagination': {'current_page': 1, 'per_page': 15, 'total': 3, 'last_page': 1},
      });

      expect(page.cases, hasLength(1));
      expect(page.currentPage, 1);
      expect(page.lastPage, 1);
      expect(page.total, 3);
    });
  });

  group('CaseHistory', () {
    test('parses the merged follow_up_history + audit_log history shape', () {
      final history = CaseHistory.fromJson({
        'collection_case_id': '01CASE',
        'history': [
          {
            'source': 'follow_up_history',
            'action': 'collection_activity',
            'details': 'Contacted — spoke with customer',
            'actor_user_id': '01USER',
            'occurred_at': '2026-07-28T09:00:00.000000Z',
          },
          {
            'source': 'audit_log',
            'action': 'StatusChanged',
            'details': null,
            'actor_user_id': null,
            'occurred_at': '2026-07-28T10:00:00.000000Z',
          },
        ],
      });

      expect(history.collectionCaseId, '01CASE');
      expect(history.entries, hasLength(2));
      expect(history.entries.first.source, 'follow_up_history');
      expect(history.entries.first.details, 'Contacted — spoke with customer');
      expect(history.entries.last.source, 'audit_log');
      expect(history.entries.last.details, isNull);
      expect(history.entries.last.actorUserId, isNull);
    });
  });
}
