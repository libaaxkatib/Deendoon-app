import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mobile/features/debts/presentation/providers/debt_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockDebtRepository extends Mock implements DebtRepository {}

const _debtOne = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2026-07-01',
  debtStatus: 'overdue',
  remainingBalance: '400.00',
  recoveryStage: 3,
  notes: null,
);

const _debtTwo = Debt(
  id: '2',
  customerId: '01CUST',
  referenceNumber: 'DBT-0002',
  amount: '500.00',
  dueDate: '2026-08-01',
  debtStatus: 'pending',
  remainingBalance: '500.00',
  recoveryStage: 1,
  notes: null,
);

void main() {
  late _MockDebtRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockDebtRepository();
    container = ProviderContainer(
      overrides: [debtRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 scoped to the customer id with no status filter', () async {
    when(() => mockRepository.fetchDebts(page: 1, customerId: '01CUST', status: null, dateFrom: null, dateTo: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtOne], currentPage: 1, lastPage: 2, total: 30));

    final state = await container.read(debtListProvider('01CUST').future);

    expect(state.debts, [_debtOne]);
    expect(state.hasMore, isTrue);
  });

  test('filterByStatus() re-fetches page 1 under the real debt_status value', () async {
    when(() => mockRepository.fetchDebts(page: 1, customerId: '01CUST', status: null, dateFrom: null, dateTo: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtOne], currentPage: 1, lastPage: 1, total: 1));
    await container.read(debtListProvider('01CUST').future);

    when(() => mockRepository.fetchDebts(page: 1, customerId: '01CUST', status: 'pending', dateFrom: null, dateTo: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtTwo], currentPage: 1, lastPage: 1, total: 1));

    await container.read(debtListProvider('01CUST').notifier).filterByStatus('pending');

    final state = container.read(debtListProvider('01CUST')).value!;
    expect(state.debts, [_debtTwo]);
    expect(state.status, 'pending');
  });

  test('loadMore() appends the next page and stops once lastPage is reached', () async {
    when(() => mockRepository.fetchDebts(page: 1, customerId: '01CUST', status: null, dateFrom: null, dateTo: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtOne], currentPage: 1, lastPage: 2, total: 2));
    await container.read(debtListProvider('01CUST').future);

    when(() => mockRepository.fetchDebts(page: 2, customerId: '01CUST', status: null, dateFrom: null, dateTo: null))
        .thenAnswer((_) async => const DebtPage(debts: [_debtTwo], currentPage: 2, lastPage: 2, total: 2));

    await container.read(debtListProvider('01CUST').notifier).loadMore();

    final state = container.read(debtListProvider('01CUST')).value!;
    expect(state.debts, [_debtOne, _debtTwo]);
    expect(state.hasMore, isFalse);
  });
}
