import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/domain/dashboard_kpis.dart';
import 'package:mobile/features/dashboard/domain/recent_case.dart';
import 'package:mobile/features/dashboard/domain/todays_overview.dart';

void main() {
  group('DashboardKpis', () {
    test('parses the exact ReportingService::dashboardKpis() shape', () {
      final kpis = DashboardKpis.fromJson({
        'scope': 'tenant',
        'period': 'month',
        'total_outstanding_amount': '800.00',
        'total_collected_period': '100.00',
        'recovery_rate': null,
        'high_risk_customers': 2,
        'total_overdue_debts': {'count': 2, 'value': '400.00'},
        'customers_over_credit_limit': 1,
        'active_collection_cases': 3,
      });

      expect(kpis.totalOutstandingAmount, '800.00');
      expect(kpis.totalCollectedPeriod, '100.00');
      expect(kpis.highRiskCustomers, 2);
      expect(kpis.overdueCount, 2);
      expect(kpis.overdueValue, '400.00');
      expect(kpis.customersOverCreditLimit, 1);
      expect(kpis.activeCollectionCases, 3);
    });
  });

  group('TodaysOverview', () {
    test(
      'reads total_due_today and the three per_type counts the UI needs',
      () {
        final overview = TodaysOverview.fromJson({
          'total_due_today': 7,
          'per_type': {
            'client_visit': 2,
            'follow_up_call': 3,
            'payment_due': 1,
            'contract_renewal': 1,
            'promise_to_pay': 0,
          },
          'overdue_count': 4,
        });

        expect(overview.totalDueToday, 7);
        expect(overview.paymentsDue, 1);
        expect(overview.clientVisits, 2);
        expect(overview.followUpCalls, 3);
      },
    );

    test('defaults an absent per_type key to zero rather than throwing', () {
      final overview = TodaysOverview.fromJson({
        'total_due_today': 0,
        'per_type': <String, dynamic>{},
        'overdue_count': 0,
      });

      expect(overview.paymentsDue, 0);
      expect(overview.clientVisits, 0);
      expect(overview.followUpCalls, 0);
    });
  });

  group('RecentCase', () {
    test(
      'parses the CollectionCaseResource fields the Recent Cases section renders',
      () {
        final recentCase = RecentCase.fromJson({
          'id': '01ABC',
          'debt_id': '01DEF',
          'customer_id': '01GHI',
          'customer_name': 'Somali Builders',
          'outstanding_amount': '800.00',
          'risk_level': 'high',
          'reference_number': 'CASE-0001',
          'case_status': 'open',
          'last_activity_at': '2026-07-28T10:00:00.000000Z',
        });

        expect(recentCase.id, '01ABC');
        expect(recentCase.customerName, 'Somali Builders');
        expect(recentCase.outstandingAmount, '800.00');
        expect(recentCase.riskLevel, 'high');
        expect(
          recentCase.lastActivityAt,
          DateTime.parse('2026-07-28T10:00:00.000000Z'),
        );
      },
    );

    test('falls back gracefully when risk_level is null', () {
      final recentCase = RecentCase.fromJson({
        'id': '01ABC',
        'customer_name': 'Somali Builders',
        'outstanding_amount': '0.00',
        'risk_level': null,
        'last_activity_at': '2026-07-28T10:00:00.000000Z',
      });

      expect(recentCase.riskLevel, isNull);
    });
  });
}
