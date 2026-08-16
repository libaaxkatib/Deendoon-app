import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/case_history.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/domain/collection_case_page.dart';
import 'package:mobile/features/cases/presentation/providers/case_actions.dart';
import 'package:mobile/features/cases/presentation/providers/case_detail_providers.dart';
import 'package:mobile/features/cases/presentation/providers/case_list_provider.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/presentation/providers/debt_detail_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollectionCaseRepository extends Mock
    implements CollectionCaseRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

const _openCase = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '400.00',
  riskLevel: 'medium',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  notes: null,
  lastActivityAt: '2026-08-01T09:00:00.000000Z',
  createdAt: '2026-08-01T09:00:00.000000Z',
  closedAt: null,
);

const _closedCase = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '400.00',
  riskLevel: 'medium',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'closed',
  closureOutcome: 'Debtor unreachable',
  notes: null,
  lastActivityAt: '2026-08-02T09:00:00.000000Z',
  createdAt: '2026-08-01T09:00:00.000000Z',
  closedAt: '2026-08-02T09:00:00.000000Z',
);

const _history = CaseHistory(collectionCaseId: '01CASE', entries: []);

void main() {
  late _MockCollectionCaseRepository mockCollectionCaseRepository;
  late _MockDebtRepository mockDebtRepository;
  late ProviderContainer container;

  setUp(() {
    mockCollectionCaseRepository = _MockCollectionCaseRepository();
    mockDebtRepository = _MockDebtRepository();
    container = ProviderContainer(
      overrides: [
        collectionCaseRepositoryProvider.overrideWithValue(
          mockCollectionCaseRepository,
        ),
        debtRepositoryProvider.overrideWithValue(mockDebtRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'Mobile Fix #13: recordActivity() invalidates caseListProvider in addition to the existing '
    'caseDetailProvider/caseHistoryProvider invalidations',
    () async {
      when(
        () => mockCollectionCaseRepository.fetchCase('01CASE'),
      ).thenAnswer((_) async => _openCase);
      when(
        () => mockCollectionCaseRepository.fetchHistory('01CASE'),
      ).thenAnswer((_) async => _history);
      when(
        () => mockCollectionCaseRepository.fetchCases(page: 1, tab: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_openCase],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      await container.read(caseDetailProvider('01CASE').future);
      await container.read(caseHistoryProvider('01CASE').future);
      await container.read(caseListProvider.future);

      when(
        () => mockCollectionCaseRepository.recordActivity(
          caseId: '01CASE',
          details: 'Called the debtor',
        ),
      ).thenAnswer((_) async {});

      await container
          .read(caseActionsProvider)
          .recordActivity(caseId: '01CASE', details: 'Called the debtor');

      await container.read(caseDetailProvider('01CASE').future);
      await container.read(caseHistoryProvider('01CASE').future);
      await container.read(caseListProvider.future);

      verify(() => mockCollectionCaseRepository.fetchCase('01CASE')).called(2);
      verify(
        () => mockCollectionCaseRepository.fetchHistory('01CASE'),
      ).called(2);
      verify(
        () => mockCollectionCaseRepository.fetchCases(page: 1, tab: null),
      ).called(2);
    },
  );

  test(
    'Mobile Fix #13: close() invalidates caseListProvider and debtRelatedCaseProvider(debtId) in addition '
    'to the existing caseDetailProvider/caseHistoryProvider invalidations',
    () async {
      when(
        () => mockCollectionCaseRepository.fetchCase('01CASE'),
      ).thenAnswer((_) async => _openCase);
      when(
        () => mockCollectionCaseRepository.fetchHistory('01CASE'),
      ).thenAnswer((_) async => _history);
      when(
        () => mockCollectionCaseRepository.fetchCases(page: 1, tab: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [_openCase],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockDebtRepository.fetchRelatedCase('01DEBT'),
      ).thenAnswer((_) async => _openCase);

      await container.read(caseDetailProvider('01CASE').future);
      await container.read(caseHistoryProvider('01CASE').future);
      await container.read(caseListProvider.future);
      await container.read(debtRelatedCaseProvider('01DEBT').future);

      when(
        () => mockCollectionCaseRepository.close(
          caseId: '01CASE',
          closureOutcome: 'Debtor unreachable',
        ),
      ).thenAnswer((_) async => _closedCase);

      await container
          .read(caseActionsProvider)
          .close(
            caseId: '01CASE',
            debtId: '01DEBT',
            closureOutcome: 'Debtor unreachable',
          );

      await container.read(caseDetailProvider('01CASE').future);
      await container.read(caseHistoryProvider('01CASE').future);
      await container.read(caseListProvider.future);
      await container.read(debtRelatedCaseProvider('01DEBT').future);

      verify(() => mockCollectionCaseRepository.fetchCase('01CASE')).called(2);
      verify(
        () => mockCollectionCaseRepository.fetchHistory('01CASE'),
      ).called(2);
      verify(
        () => mockCollectionCaseRepository.fetchCases(page: 1, tab: null),
      ).called(2);
      verify(() => mockDebtRepository.fetchRelatedCase('01DEBT')).called(2);
    },
  );

  test(
    'Mobile Fix #13: updateNotes() invalidates caseHistoryProvider in addition to the existing '
    'caseDetailProvider invalidation, since a notes edit writes an AuditLog entry the History merges in',
    () async {
      when(
        () => mockCollectionCaseRepository.fetchCase('01CASE'),
      ).thenAnswer((_) async => _openCase);
      when(
        () => mockCollectionCaseRepository.fetchHistory('01CASE'),
      ).thenAnswer((_) async => _history);

      await container.read(caseDetailProvider('01CASE').future);
      await container.read(caseHistoryProvider('01CASE').future);

      when(
        () => mockCollectionCaseRepository.updateNotes(
          caseId: '01CASE',
          notes: 'Updated notes',
        ),
      ).thenAnswer((_) async => _openCase);

      await container
          .read(caseActionsProvider)
          .updateNotes(caseId: '01CASE', notes: 'Updated notes');

      await container.read(caseDetailProvider('01CASE').future);
      await container.read(caseHistoryProvider('01CASE').future);

      verify(() => mockCollectionCaseRepository.fetchCase('01CASE')).called(2);
      verify(
        () => mockCollectionCaseRepository.fetchHistory('01CASE'),
      ).called(2);
    },
  );
}
