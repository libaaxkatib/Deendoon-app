import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/domain/aging_analysis.dart';
import 'package:mobile/features/analytics/domain/collection_analytics.dart';
import 'package:mobile/features/analytics/domain/collections_trend.dart';
import 'package:mobile/features/analytics/domain/payment_page.dart';
import 'package:mobile/features/analytics/domain/risk_distribution.dart';

void main() {
  group('CollectionAnalytics', () {
    test('parses collection_rate, total_collected, and average_days', () {
      final analytics = CollectionAnalytics.fromJson({
        'collection_rate': 40.0,
        'total_collected': '400.00',
        'average_days': 10.0,
      });

      expect(analytics.collectionRate, 40.0);
      expect(analytics.totalCollected, '400.00');
      expect(analytics.averageDays, 10.0);
    });

    test(
      'parses a null average_days when no debts were paid in the period',
      () {
        final analytics = CollectionAnalytics.fromJson({
          'collection_rate': 0.0,
          'total_collected': '0.00',
          'average_days': null,
        });

        expect(analytics.averageDays, isNull);
      },
    );
  });

  group('RiskDistribution', () {
    test('parses exactly 3 segments with count and percentage', () {
      final distribution = RiskDistribution.fromJson({
        'segments': [
          {'risk_level': 'high', 'customer_count': 1, 'percentage': 33.33},
          {'risk_level': 'medium', 'customer_count': 0, 'percentage': 0.0},
          {'risk_level': 'low', 'customer_count': 2, 'percentage': 66.67},
        ],
      });

      expect(distribution.segments, hasLength(3));
      expect(distribution.segments.first.riskLevel, 'high');
      expect(distribution.segments.first.customerCount, 1);
      expect(distribution.segments.first.percentage, 33.33);
    });
  });

  group('CollectionsTrend', () {
    test('parses metric and a zero-filled daily series', () {
      final trend = CollectionsTrend.fromJson({
        'metric': 'collected_amount',
        'series': [
          {'date': '2026-07-28', 'value': '0.00'},
          {'date': '2026-07-29', 'value': '250.00'},
        ],
      });

      expect(trend.metric, 'collected_amount');
      expect(trend.series, hasLength(2));
      expect(trend.series.last.value, '250.00');
    });
  });

  group('AgingAnalysis', () {
    test('parses all 5 real buckets, verbatim backend keys', () {
      final aging = AgingAnalysis.fromJson({
        'buckets': {
          'current': {'count': 1, 'total_remaining_balance': '100.00'},
          '1_30': {'count': 0, 'total_remaining_balance': '0.00'},
          '31_60': {'count': 0, 'total_remaining_balance': '0.00'},
          '61_90': {'count': 0, 'total_remaining_balance': '0.00'},
          'over_90': {'count': 0, 'total_remaining_balance': '0.00'},
        },
        'debts': [
          {
            'id': '01DEBT',
            'customer_id': '01CUST',
            'reference_number': 'DBT-000001',
            'amount': '500.00',
            'due_date': '2026-08-01',
            'debt_status': 'pending',
            'remaining_balance': '500.00',
            'recovery_stage': 1,
            'notes': null,
            'aging_bucket': 'current',
          },
        ],
        'pagination': {
          'current_page': 1,
          'per_page': 100,
          'total': 1,
          'last_page': 1,
        },
      });

      expect(aging.buckets.keys, containsAll(agingBucketOrder));
      expect(aging.buckets['current']!.count, 1);
      expect(aging.debts, hasLength(1));
      expect(aging.debts.first.agingBucket, 'current');
      expect(aging.debts.first.debt.referenceNumber, 'DBT-000001');
    });
  });

  group('PaymentPage', () {
    test(
      'parses the payments + pagination envelope from GET /reports/payments',
      () {
        final page = PaymentPage.fromJson({
          'payments': [
            {
              'id': '01PAY',
              'debt_id': '01DEBT',
              'amount': '100.00',
              'payment_date': '2026-07-28',
              'payment_method': null,
            },
          ],
          'pagination': {
            'current_page': 1,
            'per_page': 15,
            'total': 1,
            'last_page': 1,
          },
        });

        expect(page.payments, hasLength(1));
        expect(page.payments.first.amount, '100.00');
        expect(page.currentPage, 1);
        expect(page.total, 1);
      },
    );
  });
}
