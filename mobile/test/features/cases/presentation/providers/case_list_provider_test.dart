import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/domain/collection_case_page.dart';
import 'package:mobile/features/cases/presentation/providers/case_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollectionCaseRepository extends Mock implements CollectionCaseRepository {}

const _caseOne = CollectionCase(
  id: '1',
  debtId: '01DEBT1',
  customerId: '01CUST1',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  notes: null,
  lastActivityAt: '2026-07-28T10:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: null,
);

const _caseTwo = CollectionCase(
  id: '2',
  debtId: '01DEBT2',
  customerId: '01CUST2',
  customerName: 'Hodan Trading',
  outstandingAmount: '900.00',
  riskLevel: 'low',
  referenceNumber: 'COL-0002',
  assignedOfficerUserId: '01OFFICER',
  caseStatus: 'open',
  closureOutcome: null,
  notes: null,
  lastActivityAt: '2026-07-27T10:00:00.000000Z',
  createdAt: '2026-06-01T10:00:00.000000Z',
  closedAt: null,
);

void main() {
  late _MockCollectionCaseRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockCollectionCaseRepository();
    container = ProviderContainer(
      overrides: [collectionCaseRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no tab filter', () async {
    when(() => mockRepository.fetchCases(page: 1, tab: null))
        .thenAnswer((_) async => const CollectionCasePage(cases: [_caseOne], currentPage: 1, lastPage: 2, total: 30));

    final state = await container.read(caseListProvider.future);

    expect(state.cases, [_caseOne]);
    expect(state.hasMore, isTrue);
  });

  test('filterByTab() re-fetches page 1 under the real tab value', () async {
    when(() => mockRepository.fetchCases(page: 1, tab: null))
        .thenAnswer((_) async => const CollectionCasePage(cases: [_caseOne], currentPage: 1, lastPage: 1, total: 1));
    await container.read(caseListProvider.future);

    when(() => mockRepository.fetchCases(page: 1, tab: 'high_risk'))
        .thenAnswer((_) async => const CollectionCasePage(cases: [_caseOne], currentPage: 1, lastPage: 1, total: 1));

    await container.read(caseListProvider.notifier).filterByTab('high_risk');

    final state = container.read(caseListProvider).value!;
    expect(state.cases, [_caseOne]);
    expect(state.tab, 'high_risk');
  });

  test('loadMore() appends the next page and stops once lastPage is reached', () async {
    when(() => mockRepository.fetchCases(page: 1, tab: null))
        .thenAnswer((_) async => const CollectionCasePage(cases: [_caseOne], currentPage: 1, lastPage: 2, total: 2));
    await container.read(caseListProvider.future);

    when(() => mockRepository.fetchCases(page: 2, tab: null))
        .thenAnswer((_) async => const CollectionCasePage(cases: [_caseTwo], currentPage: 2, lastPage: 2, total: 2));

    await container.read(caseListProvider.notifier).loadMore();

    final state = container.read(caseListProvider).value!;
    expect(state.cases, [_caseOne, _caseTwo]);
    expect(state.hasMore, isFalse);
  });
}
