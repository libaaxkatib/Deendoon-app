import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/presentation/providers/average_days_debts_provider.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

const _debt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '500.00',
  dueDate: '2026-01-01',
  debtStatus: 'paid',
  remainingBalance: '0.00',
  recoveryStage: 1,
  notes: null,
);

void main() {
  late _MockAnalyticsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
    container = ProviderContainer(overrides: [analyticsRepositoryProvider.overrideWithValue(mockRepository)]);
    addTearDown(container.dispose);
  });

  test('fetches debts paid in the given range via the real paidDateFrom/paidDateTo filter', () async {
    final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
    when(() => mockRepository.fetchReportDebts(
          page: 1,
          paidDateFrom: '2026-01-01',
          paidDateTo: '2026-01-31',
          perPage: 100,
        )).thenAnswer((_) async => const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1));

    final result = await container.read(averageDaysDebtsProvider(range).future);

    expect(result, [_debt]);
  });
}
