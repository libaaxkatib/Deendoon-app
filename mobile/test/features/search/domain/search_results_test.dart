import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/search/domain/search_results.dart';

void main() {
  test('parses every entity type present in the real SearchController response', () {
    final results = SearchResults.fromJson({
      'customers': [
        {
          'id': '1',
          'name': 'Asad',
          'phone': '0612345678',
          'customer_status': 'active',
          'credit_limit': '1000.00',
          'outstanding_balance': '200.00',
          'remaining_credit': '800.00',
          'risk_level': 'low',
          'credit_score': 80,
          'credit_score_band': 'good',
          'archived_at': null,
          'created_at': '2026-01-01T00:00:00.000000Z',
          'updated_at': '2026-01-01T00:00:00.000000Z',
        },
      ],
      'debts': [
        {
          'id': '2',
          'customer_id': '1',
          'reference_number': 'DEBT-001',
          'amount': '500.00',
          'due_date': '2026-02-01',
          'debt_status': 'pending',
          'remaining_balance': '500.00',
          'recovery_stage': 0,
          'notes': null,
        },
      ],
      'payments': [
        {
          'id': '3',
          'debt_id': '2',
          'amount': '100.00',
          'payment_date': '2026-01-15',
          'payment_method': 'cash',
          'reference_notes': 'DEBT-001 partial',
          'recorded_by_user_id': '1',
          'created_at': '2026-01-15T00:00:00.000000Z',
        },
      ],
      'receipts': [
        {
          'id': '4',
          'document_type': 'receipt',
          'payment_id': '3',
          'reference_number': 'RCPT-001',
          'generated_at': '2026-01-15T00:00:00.000000Z',
          'file_size': 1024,
        },
      ],
      'demand_letters': null,
      'statements': null,
      'collection_cases': [
        {
          'id': '5',
          'debt_id': '2',
          'customer_id': '1',
          'customer_name': 'Asad',
          'outstanding_amount': '500.00',
          'risk_level': 'low',
          'reference_number': 'CASE-001',
          'assigned_officer_user_id': null,
          'case_status': 'open',
          'closure_outcome': null,
          'last_activity_at': '2026-01-15T00:00:00.000000Z',
          'created_at': '2026-01-01T00:00:00.000000Z',
          'updated_at': '2026-01-15T00:00:00.000000Z',
          'closed_at': null,
        },
      ],
    });

    expect(results.customers, hasLength(1));
    expect(results.debts, hasLength(1));
    expect(results.payments, hasLength(1));
    expect(results.receipts, hasLength(1));
    expect(results.demandLetters, isNull);
    expect(results.statements, isNull);
    expect(results.collectionCases, hasLength(1));
    expect(results.documents, hasLength(1));
    expect(results.totalCount, 5);
  });

  test('a null category means the role cannot view that entity, not "no matches"', () {
    final results = SearchResults.fromJson({
      'customers': null,
      'debts': null,
      'payments': null,
      'receipts': null,
      'demand_letters': null,
      'statements': null,
      'collection_cases': null,
    });

    expect(results.customers, isNull);
    expect(results.totalCount, 0);
  });

  test('an empty list means the role can view the entity but nothing matched', () {
    final results = SearchResults.fromJson({
      'customers': [],
      'debts': null,
      'payments': null,
      'receipts': null,
      'demand_letters': null,
      'statements': null,
      'collection_cases': null,
    });

    expect(results.customers, isEmpty);
    expect(results.customers, isNotNull);
    expect(results.totalCount, 0);
  });
}
