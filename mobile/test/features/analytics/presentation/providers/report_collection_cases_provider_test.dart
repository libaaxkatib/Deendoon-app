import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/presentation/providers/report_collection_cases_provider.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/domain/collection_case_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

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
  late _MockAnalyticsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
    container = ProviderContainer(
      overrides: [
        analyticsRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('build() fetches page 1 with no status filter', () async {
    when(
      () => mockRepository.fetchReportCollectionCases(page: 1, status: null),
    ).thenAnswer(
      (_) async => const CollectionCasePage(
        cases: [_caseOne],
        currentPage: 1,
        lastPage: 2,
        total: 20,
      ),
    );

    final state = await container.read(reportCollectionCasesProvider.future);

    expect(state.cases, [_caseOne]);
    expect(state.hasMore, isTrue);
  });

  test(
    'loadMore() appends the next page and stops once lastPage is reached',
    () async {
      when(
        () => mockRepository.fetchReportCollectionCases(page: 1, status: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_caseOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCollectionCasesProvider.future);

      when(
        () => mockRepository.fetchReportCollectionCases(page: 2, status: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_caseTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportCollectionCasesProvider.notifier).loadMore();

      final state = container.read(reportCollectionCasesProvider).value!;
      expect(state.cases, [_caseOne, _caseTwo]);
      expect(state.hasMore, isFalse);
    },
  );

  test(
    'loadMore() sets loadMoreError and preserves existing state when the request fails',
    () async {
      when(
        () => mockRepository.fetchReportCollectionCases(page: 1, status: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_caseOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCollectionCasesProvider.future);

      when(
        () => mockRepository.fetchReportCollectionCases(page: 2, status: null),
      ).thenThrow(Exception('network error'));

      await container.read(reportCollectionCasesProvider.notifier).loadMore();

      final state = container.read(reportCollectionCasesProvider).value!;
      expect(state.loadMoreError, isTrue);
      expect(state.isLoadingMore, isFalse);
      expect(state.cases, [_caseOne]);
      expect(state.currentPage, 1);
      expect(state.hasMore, isTrue);
    },
  );

  test(
    'loadMore() retried after a failure clears loadMoreError, re-requests the same page, and appends on success',
    () async {
      when(
        () => mockRepository.fetchReportCollectionCases(page: 1, status: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_caseOne],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      await container.read(reportCollectionCasesProvider.future);

      when(
        () => mockRepository.fetchReportCollectionCases(page: 2, status: null),
      ).thenThrow(Exception('network error'));
      await container.read(reportCollectionCasesProvider.notifier).loadMore();
      expect(
        container.read(reportCollectionCasesProvider).value!.loadMoreError,
        isTrue,
      );

      when(
        () => mockRepository.fetchReportCollectionCases(page: 2, status: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_caseTwo],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await container.read(reportCollectionCasesProvider.notifier).loadMore();

      final state = container.read(reportCollectionCasesProvider).value!;
      expect(state.loadMoreError, isFalse);
      expect(state.cases, [_caseOne, _caseTwo]);
      expect(state.hasMore, isFalse);
      verify(
        () => mockRepository.fetchReportCollectionCases(page: 2, status: null),
      ).called(2);
    },
  );
}
