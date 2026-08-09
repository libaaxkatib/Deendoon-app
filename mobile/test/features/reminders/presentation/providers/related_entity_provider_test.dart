import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/promise_to_pay.dart';
import 'package:mobile/features/reminders/presentation/providers/related_entity_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockCollectionCaseRepository extends Mock implements CollectionCaseRepository {}

const _customer = Customer(
  id: '01CUST',
  name: 'Somali Builders',
  phone: '+252612345678',
  address: '123 Market Street',
  customerStatus: 'good_standing',
  creditLimit: '5000.00',
  outstandingBalance: '800.00',
  remainingCredit: '4200.00',
  riskLevel: 'low',
  creditScore: 720,
  creditScoreBand: 'good',
  archivedAt: null,
);

const _debt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2026-07-01',
  debtStatus: 'pending',
  remainingBalance: '1000.00',
  recoveryStage: 1,
  notes: null,
);

const _promise = PromiseToPay(
  id: '01PROMISE',
  debtId: '1',
  promisedDate: '2026-08-15',
  status: 'open',
  createdAt: '2026-08-01T10:00:00.000000Z',
);

void main() {
  late _MockCustomerRepository mockCustomerRepository;
  late _MockDebtRepository mockDebtRepository;
  late _MockCollectionCaseRepository mockCollectionCaseRepository;
  late ProviderContainer container;

  setUp(() {
    mockCustomerRepository = _MockCustomerRepository();
    mockDebtRepository = _MockDebtRepository();
    mockCollectionCaseRepository = _MockCollectionCaseRepository();
    container = ProviderContainer(overrides: [
      customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
      debtRepositoryProvider.overrideWithValue(mockDebtRepository),
      collectionCaseRepositoryProvider.overrideWithValue(mockCollectionCaseRepository),
    ]);
    addTearDown(container.dispose);
  });

  test('customer type resolves the real customer name/phone/address', () async {
    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);

    final result = await container.read(relatedEntityProvider('customer:01CUST').future);

    expect(result.name, 'Somali Builders');
    expect(result.resolved, isTrue);
    expect(result.phone, '+252612345678');
    expect(result.address, '123 Market Street');
  });

  test('debt type resolves through the debt to its customer', () async {
    when(() => mockDebtRepository.fetchDebt('1')).thenAnswer((_) async => _debt);
    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);

    final result = await container.read(relatedEntityProvider('debt:1').future);

    expect(result.name, 'Somali Builders');
    expect(result.address, '123 Market Street');
  });

  test('collection_case type uses the embedded customer_name (no address available)', () async {
    const collectionCase = CollectionCase(
      id: '01CASE',
      debtId: '1',
      customerId: '01CUST',
      customerName: 'Somali Builders',
      outstandingAmount: '1000.00',
      riskLevel: 'low',
      referenceNumber: 'COL-0001',
      assignedOfficerUserId: null,
      caseStatus: 'open',
      closureOutcome: null,
      notes: null,
      lastActivityAt: '2026-08-01T10:00:00.000000Z',
      createdAt: '2026-08-01T10:00:00.000000Z',
      closedAt: null,
    );
    when(() => mockCollectionCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => collectionCase);

    final result = await container.read(relatedEntityProvider('collection_case:01CASE').future);

    expect(result.name, 'Somali Builders');
    expect(result.resolved, isTrue);
    expect(result.address, isNull);
  });

  test('promise_to_pay type resolves the real customer name via promise -> debt -> customer (Item 14)', () async {
    when(() => mockDebtRepository.fetchPromiseToPayById('01PROMISE')).thenAnswer((_) async => _promise);
    when(() => mockDebtRepository.fetchDebt('1')).thenAnswer((_) async => _debt);
    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);

    final result = await container.read(relatedEntityProvider('promise_to_pay:01PROMISE').future);

    expect(result.name, 'Somali Builders');
    expect(result.resolved, isTrue);
    expect(result.address, '123 Market Street');
  });

  test('an unknown type falls back to the raw type, unresolved', () async {
    final result = await container.read(relatedEntityProvider('something_else:1').future);

    expect(result.name, 'something_else');
    expect(result.resolved, isFalse);
  });

  test('a dangling reference (404) resolves to "Not available", unresolved', () async {
    when(() => mockCustomerRepository.fetchCustomer('01MISSING'))
        .thenThrow(const ApiException(message: 'Not found.', statusCode: 404));

    final result = await container.read(relatedEntityProvider('customer:01MISSING').future);

    expect(result.name, 'Not available');
    expect(result.resolved, isFalse);
  });
}
