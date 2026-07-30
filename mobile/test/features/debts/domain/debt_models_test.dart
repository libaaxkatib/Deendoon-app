import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mobile/features/debts/domain/debt_timeline.dart';
import 'package:mobile/features/debts/domain/promise_to_pay.dart';

Map<String, dynamic> _debtJson({String debtStatus = 'overdue', String dueDate = '2026-07-01'}) => {
      'id': '01DEBT',
      'customer_id': '01CUST',
      'reference_number': 'DBT-0001',
      'amount': '1000.00',
      'due_date': dueDate,
      'debt_status': debtStatus,
      'remaining_balance': '400.00',
      'recovery_stage': 3,
      'notes': 'Some notes',
    };

void main() {
  group('Debt', () {
    test('parses the exact DebtResource shape', () {
      final debt = Debt.fromJson(_debtJson());

      expect(debt.id, '01DEBT');
      expect(debt.customerId, '01CUST');
      expect(debt.referenceNumber, 'DBT-0001');
      expect(debt.amount, '1000.00');
      expect(debt.dueDate, '2026-07-01');
      expect(debt.debtStatus, 'overdue');
      expect(debt.remainingBalance, '400.00');
      expect(debt.recoveryStage, 3);
      expect(debt.notes, 'Some notes');
    });

    test('daysOverdue is positive for a past due_date on an open debt', () {
      final debt = Debt.fromJson(_debtJson(debtStatus: 'overdue', dueDate: '2026-07-01'));

      final days = debt.daysOverdue(now: DateTime(2026, 7, 28));

      expect(days, 27);
    });

    test('daysOverdue is null when the due date is in the future', () {
      final debt = Debt.fromJson(_debtJson(debtStatus: 'pending', dueDate: '2026-08-01'));

      expect(debt.daysOverdue(now: DateTime(2026, 7, 28)), isNull);
    });

    test('daysOverdue is null for a closed debt even past its due date', () {
      final debt = Debt.fromJson(_debtJson(debtStatus: 'paid', dueDate: '2026-01-01'));

      expect(debt.daysOverdue(now: DateTime(2026, 7, 28)), isNull);
    });
  });

  group('DebtPage', () {
    test('parses the debts + pagination envelope from GET /debts', () {
      final page = DebtPage.fromJson({
        'debts': [_debtJson()],
        'pagination': {'current_page': 1, 'per_page': 20, 'total': 5, 'last_page': 1},
      });

      expect(page.debts, hasLength(1));
      expect(page.currentPage, 1);
      expect(page.lastPage, 1);
      expect(page.total, 5);
    });
  });

  group('DocumentSummary', () {
    test('parses the common shape shared by all four document resources', () {
      final document = DocumentSummary.fromJson({
        'id': '01DOC',
        'document_type': 'receipt',
        'reference_number': 'REC-0001',
        'generated_at': '2026-07-20T10:00:00.000000Z',
        'file_size': 1024,
      });

      expect(document.id, '01DOC');
      expect(document.documentType, 'receipt');
      expect(document.referenceNumber, 'REC-0001');
      expect(document.fileSize, 1024);
    });
  });

  group('PromiseToPay', () {
    test('parses the exact PromiseToPayResource shape', () {
      final promise = PromiseToPay.fromJson({
        'id': '01PROM',
        'debt_id': '01DEBT',
        'promised_date': '2026-08-01',
        'status': 'open',
        'created_by_user_id': 1,
        'created_at': '2026-07-20T10:00:00.000000Z',
        'resolved_at': null,
      });

      expect(promise.id, '01PROM');
      expect(promise.debtId, '01DEBT');
      expect(promise.promisedDate, '2026-08-01');
      expect(promise.status, 'open');
    });
  });

  group('DebtTimeline', () {
    test('parses the 8-stage FR-024 timeline shape', () {
      final timeline = DebtTimeline.fromJson({
        'debt_id': '01DEBT',
        'stages': [
          {'event': 'debt_created', 'status': 'completed', 'occurred_at': '2026-07-01T00:00:00.000000Z'},
          {'event': 'whatsapp_reminder', 'status': 'pending', 'occurred_at': null},
        ],
      });

      expect(timeline.debtId, '01DEBT');
      expect(timeline.stages, hasLength(2));
      expect(timeline.stages.first.event, 'debt_created');
      expect(timeline.stages.first.status, 'completed');
      expect(timeline.stages.last.status, 'pending');
      expect(timeline.stages.last.occurredAt, isNull);
    });
  });
}
