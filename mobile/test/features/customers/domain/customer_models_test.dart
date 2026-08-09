import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mobile/core/models/payment.dart';

void main() {
  group('Customer', () {
    test('parses the exact CustomerResource shape', () {
      final customer = Customer.fromJson({
        'id': '01ABC',
        'name': 'Somali Builders',
        'phone': '+252612345678',
        'customer_status': 'good_standing',
        'credit_limit': '5000.00',
        'outstanding_balance': '800.00',
        'remaining_credit': '4200.00',
        'risk_level': 'low',
        'credit_score': 720,
        'credit_score_band': 'good',
      });

      expect(customer.id, '01ABC');
      expect(customer.name, 'Somali Builders');
      expect(customer.phone, '+252612345678');
      expect(customer.customerStatus, 'good_standing');
      expect(customer.creditLimit, '5000.00');
      expect(customer.outstandingBalance, '800.00');
      expect(customer.remainingCredit, '4200.00');
      expect(customer.riskLevel, 'low');
      expect(customer.creditScore, 720);
      expect(customer.creditScoreBand, 'good');
    });

    test('tolerates null risk_level/credit_score/credit_score_band', () {
      final customer = Customer.fromJson({
        'id': '01ABC',
        'name': 'New Customer',
        'phone': '+252611111111',
        'customer_status': 'active',
        'credit_limit': '0.00',
        'outstanding_balance': '0.00',
        'remaining_credit': '0.00',
        'risk_level': null,
        'credit_score': null,
        'credit_score_band': null,
      });

      expect(customer.riskLevel, isNull);
      expect(customer.creditScore, isNull);
      expect(customer.creditScoreBand, isNull);
    });

    test('parses is_read_only: true (FR-083, over the plan\'s effective customer limit)', () {
      final customer = Customer.fromJson({
        'id': '01ABC',
        'name': 'Somali Builders',
        'phone': '+252612345678',
        'customer_status': 'good_standing',
        'credit_limit': '5000.00',
        'outstanding_balance': '800.00',
        'remaining_credit': '4200.00',
        'risk_level': 'low',
        'credit_score': 720,
        'credit_score_band': 'good',
        'is_read_only': true,
      });

      expect(customer.isReadOnly, isTrue);
    });

    test('defaults isReadOnly to false when the field is absent', () {
      final customer = Customer.fromJson({
        'id': '01ABC',
        'name': 'Somali Builders',
        'phone': '+252612345678',
        'customer_status': 'good_standing',
        'credit_limit': '5000.00',
        'outstanding_balance': '800.00',
        'remaining_credit': '4200.00',
        'risk_level': null,
        'credit_score': null,
        'credit_score_band': null,
      });

      expect(customer.isReadOnly, isFalse);
    });
  });

  group('CustomerPage', () {
    test('parses the customers + pagination envelope from GET /customers', () {
      final page = CustomerPage.fromJson({
        'customers': [
          {
            'id': '1',
            'name': 'A',
            'phone': '123',
            'customer_status': 'active',
            'credit_limit': '0.00',
            'outstanding_balance': '0.00',
            'remaining_credit': '0.00',
            'risk_level': null,
            'credit_score': null,
            'credit_score_band': null,
          },
        ],
        'pagination': {'current_page': 1, 'per_page': 20, 'total': 45, 'last_page': 3},
      });

      expect(page.customers, hasLength(1));
      expect(page.currentPage, 1);
      expect(page.lastPage, 3);
      expect(page.total, 45);
    });
  });

  group('Payment', () {
    test('parses the exact PaymentResource shape', () {
      final payment = Payment.fromJson({
        'id': '01PAY',
        'debt_id': '01DEBT',
        'amount': '250.00',
        'payment_date': '2026-07-20',
        'payment_method': 'cash',
        'reference_notes': null,
        'recorded_by_user_id': 1,
        'created_at': '2026-07-20T10:00:00.000000Z',
      });

      expect(payment.id, '01PAY');
      expect(payment.debtId, '01DEBT');
      expect(payment.amount, '250.00');
      expect(payment.paymentDate, '2026-07-20');
      expect(payment.paymentMethod, 'cash');
    });

    test('parses a null payment_method without throwing (it is genuinely optional)', () {
      final payment = Payment.fromJson({
        'id': '01PAY',
        'debt_id': '01DEBT',
        'amount': '250.00',
        'payment_date': '2026-07-20',
        'payment_method': null,
        'reference_notes': null,
        'recorded_by_user_id': 1,
        'created_at': '2026-07-20T10:00:00.000000Z',
      });

      expect(payment.paymentMethod, isNull);
    });
  });
}
