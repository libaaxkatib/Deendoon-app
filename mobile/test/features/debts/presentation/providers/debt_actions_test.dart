import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/domain/collection_case_page.dart';
import 'package:mobile/features/cases/presentation/providers/case_list_provider.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/presentation/providers/customer_detail_providers.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mobile/features/debts/domain/debt_timeline.dart';
import 'package:mobile/features/debts/domain/promise_to_pay.dart';
import 'package:mobile/features/debts/presentation/providers/debt_actions.dart';
import 'package:mobile/features/debts/presentation/providers/debt_detail_providers.dart';
import 'package:mobile/features/debts/presentation/providers/debt_list_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockCollectionCaseRepository extends Mock
    implements CollectionCaseRepository {}

const _debt = Debt(
  id: '01DEBT',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2026-08-01',
  debtStatus: 'partial_paid',
  remainingBalance: '400.00',
  recoveryStage: 3,
  notes: null,
);

const _payment = Payment(
  id: '01PAY',
  debtId: '01DEBT',
  amount: '250.00',
  paymentDate: '2026-08-01',
  paymentMethod: 'cash',
);

const _customer = Customer(
  id: '01CUST',
  name: 'Somali Builders',
  phone: '111',
  customerStatus: 'active',
  creditLimit: '0.00',
  outstandingBalance: '0.00',
  remainingCredit: '0.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: null,
);

const _document = DocumentSummary(
  id: '01DOC',
  documentType: 'receipt',
  referenceNumber: 'RCT-0001',
  generatedAt: '2026-08-01T00:00:00.000000Z',
  fileSize: 1024,
);

const _timeline = DebtTimeline(debtId: '01DEBT', stages: []);

const _promise = PromiseToPay(
  id: '01PTP',
  debtId: '01DEBT',
  promisedDate: '2026-08-05',
  status: 'fulfilled',
  createdAt: '2026-08-01T00:00:00.000000Z',
);

const _collectionCase = CollectionCase(
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

void main() {
  late _MockDebtRepository mockDebtRepository;
  late _MockCustomerRepository mockCustomerRepository;
  late _MockCollectionCaseRepository mockCollectionCaseRepository;
  late ProviderContainer container;

  setUp(() {
    mockDebtRepository = _MockDebtRepository();
    mockCustomerRepository = _MockCustomerRepository();
    mockCollectionCaseRepository = _MockCollectionCaseRepository();
    container = ProviderContainer(
      overrides: [
        debtRepositoryProvider.overrideWithValue(mockDebtRepository),
        customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
        collectionCaseRepositoryProvider.overrideWithValue(
          mockCollectionCaseRepository,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'Mobile Fix #13: recordPayment() invalidates every provider whose backend-displayed data changed, '
    'while preserving the pre-existing debt-scoped invalidations',
    () async {
      when(
        () => mockDebtRepository.fetchDebt('01DEBT'),
      ).thenAnswer((_) async => _debt);
      when(
        () => mockDebtRepository.fetchPayments('01DEBT'),
      ).thenAnswer((_) async => [_payment]);
      when(
        () => mockDebtRepository.fetchDocuments('01DEBT'),
      ).thenAnswer((_) async => [_document]);
      when(
        () => mockDebtRepository.fetchTimeline('01DEBT'),
      ).thenAnswer((_) async => _timeline);
      when(
        () => mockDebtRepository.fetchPromiseToPayHistory('01DEBT'),
      ).thenAnswer((_) async => [_promise]);
      when(
        () => mockCustomerRepository.fetchCustomer('01CUST'),
      ).thenAnswer((_) async => _customer);
      when(
        () => mockCustomerRepository.fetchPayments('01CUST'),
      ).thenAnswer((_) async => [_payment]);
      when(
        () => mockDebtRepository.fetchDebts(
          page: 1,
          customerId: '01CUST',
          status: null,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async => const DebtPage(
          debts: [_debt],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      // Seed every affected provider once, before the mutation.
      await container.read(debtDetailProvider('01DEBT').future);
      await container.read(debtPaymentsProvider('01DEBT').future);
      await container.read(debtDocumentsProvider('01DEBT').future);
      await container.read(debtTimelineProvider('01DEBT').future);
      await container.read(debtPromiseToPayHistoryProvider('01DEBT').future);
      await container.read(customerDetailProvider('01CUST').future);
      await container.read(customerPaymentsProvider('01CUST').future);
      await container.read(debtListProvider('01CUST').future);

      when(
        () => mockDebtRepository.recordPayment(
          debtId: '01DEBT',
          amount: '250.00',
          paymentDate: any(named: 'paymentDate'),
          paymentMethod: null,
          referenceNotes: null,
        ),
      ).thenAnswer((_) async => _payment);

      await container
          .read(debtActionsProvider)
          .recordPayment(
            debtId: '01DEBT',
            customerId: '01CUST',
            amount: '250.00',
            paymentDate: '2026-08-01',
          );

      // Re-reading each provider must trigger a genuine second fetch —
      // proof the mutation actually invalidated it.
      await container.read(debtDetailProvider('01DEBT').future);
      await container.read(debtPaymentsProvider('01DEBT').future);
      await container.read(debtDocumentsProvider('01DEBT').future);
      await container.read(debtTimelineProvider('01DEBT').future);
      await container.read(debtPromiseToPayHistoryProvider('01DEBT').future);
      await container.read(customerDetailProvider('01CUST').future);
      await container.read(customerPaymentsProvider('01CUST').future);
      await container.read(debtListProvider('01CUST').future);

      verify(() => mockDebtRepository.fetchDebt('01DEBT')).called(2);
      verify(() => mockDebtRepository.fetchPayments('01DEBT')).called(2);
      verify(() => mockDebtRepository.fetchDocuments('01DEBT')).called(2);
      verify(() => mockDebtRepository.fetchTimeline('01DEBT')).called(2);
      verify(
        () => mockDebtRepository.fetchPromiseToPayHistory('01DEBT'),
      ).called(2);
      verify(() => mockCustomerRepository.fetchCustomer('01CUST')).called(2);
      verify(() => mockCustomerRepository.fetchPayments('01CUST')).called(2);
      verify(
        () => mockDebtRepository.fetchDebts(
          page: 1,
          customerId: '01CUST',
          status: null,
          dateFrom: null,
          dateTo: null,
        ),
      ).called(2);
    },
  );

  test(
    'Mobile Fix #13: openCase() invalidates every provider whose backend-displayed data changed, '
    'while preserving the pre-existing debtRelatedCaseProvider invalidation',
    () async {
      when(
        () => mockDebtRepository.fetchRelatedCase('01DEBT'),
      ).thenAnswer((_) async => null);
      when(
        () => mockDebtRepository.fetchDebt('01DEBT'),
      ).thenAnswer((_) async => _debt);
      when(
        () => mockCustomerRepository.fetchCustomer('01CUST'),
      ).thenAnswer((_) async => _customer);
      when(
        () => mockCollectionCaseRepository.fetchCases(page: 1, tab: null),
      ).thenAnswer(
        (_) async => const CollectionCasePage(
          cases: [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      );
      when(
        () => mockCollectionCaseRepository.fetchCasesForCustomer('01CUST'),
      ).thenAnswer((_) async => []);

      await container.read(debtRelatedCaseProvider('01DEBT').future);
      await container.read(debtDetailProvider('01DEBT').future);
      await container.read(customerDetailProvider('01CUST').future);
      await container.read(caseListProvider.future);
      await container.read(customerCasesProvider('01CUST').future);

      when(
        () => mockDebtRepository.openCase('01DEBT'),
      ).thenAnswer((_) async => _collectionCase);

      await container.read(debtActionsProvider).openCase('01DEBT', '01CUST');

      await container.read(debtRelatedCaseProvider('01DEBT').future);
      await container.read(debtDetailProvider('01DEBT').future);
      await container.read(customerDetailProvider('01CUST').future);
      await container.read(caseListProvider.future);
      await container.read(customerCasesProvider('01CUST').future);

      verify(() => mockDebtRepository.fetchRelatedCase('01DEBT')).called(2);
      verify(() => mockDebtRepository.fetchDebt('01DEBT')).called(2);
      verify(() => mockCustomerRepository.fetchCustomer('01CUST')).called(2);
      verify(
        () => mockCollectionCaseRepository.fetchCases(page: 1, tab: null),
      ).called(2);
      verify(
        () => mockCollectionCaseRepository.fetchCasesForCustomer('01CUST'),
      ).called(2);
    },
  );
}
