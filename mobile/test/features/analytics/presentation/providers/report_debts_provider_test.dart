import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/presentation/providers/report_debts_provider.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

const _debtOne = Debt(
  id: '1',
  customerId: '1',
  referenceNumber: 'DBT-000001',
  amount: '500.00',
  dueDate: '2026-08-01',
  debtStatus: 'pending',
  remainingBalance: '500.00',
  recoveryStage: 1,
  notes: null,
);

const _debtTwo = Debt(
  id: '2',
  customerId: '2',
  referenceNumber: 'DBT-000002',
  amount: '300.00',
  dueDate: '2026-06-01',
  debtStatus: 'overdue',
  remainingBalance: '300.00',
  recoveryStage: 2,
  notes: null,
);

void main() {
  late _MockAnalyticsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
    container = ProviderContainer(
      overrides: [analyticsRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no status filter', () async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtOne], currentPage: 1, lastPage: 2, total: 20));

    final state = await container.read(reportDebtsProvider.future);

    expect(state.debts, [_debtOne]);
    expect(state.hasMore, isTrue);
  });

  test('filterByStatus() re-fetches page 1 under the real debt_status value', () async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtOne], currentPage: 1, lastPage: 1, total: 1));
    await container.read(reportDebtsProvider.future);

    when(() => mockRepository.fetchReportDebts(page: 1, status: 'overdue'))
        .thenAnswer((_) async => const DebtPage(debts: [_debtTwo], currentPage: 1, lastPage: 1, total: 1));

    await container.read(reportDebtsProvider.notifier).filterByStatus('overdue');

    final state = container.read(reportDebtsProvider).value!;
    expect(state.debts, [_debtTwo]);
    expect(state.status, 'overdue');
  });

  test('loadMore() appends the next page and stops once lastPage is reached', () async {
    when(() => mockRepository.fetchReportDebts(page: 1, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtOne], currentPage: 1, lastPage: 2, total: 2));
    await container.read(reportDebtsProvider.future);

    when(() => mockRepository.fetchReportDebts(page: 2, status: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtTwo], currentPage: 2, lastPage: 2, total: 2));

    await container.read(reportDebtsProvider.notifier).loadMore();

    final state = container.read(reportDebtsProvider).value!;
    expect(state.debts, [_debtOne, _debtTwo]);
    expect(state.hasMore, isFalse);
  });
}
