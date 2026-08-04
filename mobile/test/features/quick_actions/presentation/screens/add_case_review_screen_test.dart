import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/quick_actions/domain/add_case_review_input.dart';
import 'package:mobile/features/quick_actions/domain/customer_draft.dart';
import 'package:mobile/features/quick_actions/domain/debt_draft.dart';
import 'package:mobile/features/quick_actions/presentation/screens/add_case_review_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

const _existingCustomer = Customer(
  id: '01CUST',
  name: 'Somali Builders',
  phone: '+252612345678',
  customerStatus: 'good_standing',
  creditLimit: '5000.00',
  outstandingBalance: '800.00',
  remainingCredit: '4200.00',
  riskLevel: 'low',
  creditScore: 720,
  creditScoreBand: 'good',
  archivedAt: null,
);

const _newCustomer = Customer(
  id: '01NEW',
  name: 'New Traders',
  phone: '+252699999999',
  customerStatus: 'active',
  creditLimit: '1000.00',
  outstandingBalance: '0.00',
  remainingCredit: '1000.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: null,
);

const _debt = Debt(
  id: '01DEBT',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '500.00',
  dueDate: '2026-08-15',
  debtStatus: 'pending',
  remainingBalance: '500.00',
  recoveryStage: 1,
  notes: null,
);

const _collectionCase = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '500.00',
  riskLevel: 'low',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  lastActivityAt: '2026-08-01T10:00:00.000000Z',
  createdAt: '2026-08-01T10:00:00.000000Z',
  closedAt: null,
);

const _debtDraft = DebtDraft(amount: '500.00', dueDate: '2026-08-15');

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AddCaseReviewInput input,
  required _MockCustomerRepository customerRepository,
  required _MockDebtRepository debtRepository,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => AddCaseReviewScreen(input: input)),
      GoRoute(path: '/cases/:id', builder: (_, state) => Text('Case Detail ${state.pathParameters['id']}')),
      GoRoute(path: '/customers/:id', builder: (_, state) => Text('Customer Detail ${state.pathParameters['id']}')),
      GoRoute(path: '/debts/:id', builder: (_, state) => Text('Debt Detail ${state.pathParameters['id']}')),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerRepositoryProvider.overrideWithValue(customerRepository),
        debtRepositoryProvider.overrideWithValue(debtRepository),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockCustomerRepository mockCustomerRepository;
  late _MockDebtRepository mockDebtRepository;

  setUp(() {
    mockCustomerRepository = _MockCustomerRepository();
    mockDebtRepository = _MockDebtRepository();
  });

  testWidgets('Existing Customer path: full success chains Debt then Case and navigates to Case Detail',
      (tester) async {
    when(() => mockDebtRepository.createDebt(customerId: '01CUST', amount: '500.00', dueDate: '2026-08-15', notes: null))
        .thenAnswer((_) async => (debt: _debt, warning: null));
    when(() => mockDebtRepository.openCase('01DEBT')).thenAnswer((_) async => _collectionCase);

    await _pumpScreen(
      tester,
      input: const AddCaseReviewInput(existingCustomer: _existingCustomer, debtDraft: _debtDraft),
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );

    expect(find.text('Somali Builders'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Debt'));
    await tester.pumpAndSettle();

    verifyNever(() => mockCustomerRepository.createCustomer(
          name: any(named: 'name'),
          phone: any(named: 'phone'),
          creditLimit: any(named: 'creditLimit'),
        ));
    verify(() => mockDebtRepository.createDebt(customerId: '01CUST', amount: '500.00', dueDate: '2026-08-15', notes: null))
        .called(1);
    verify(() => mockDebtRepository.openCase('01DEBT')).called(1);
    expect(find.text('Case Detail 01CASE'), findsOneWidget);
  });

  testWidgets('New Customer path: full success chains Customer then Debt then Case', (tester) async {
    when(() => mockCustomerRepository.createCustomer(name: 'New Traders', phone: '+252699999999', creditLimit: '1000.00'))
        .thenAnswer((_) async => (customer: _newCustomer, warning: null));
    when(() => mockDebtRepository.createDebt(customerId: '01NEW', amount: '500.00', dueDate: '2026-08-15', notes: null))
        .thenAnswer((_) async => (debt: _debt, warning: null));
    when(() => mockDebtRepository.openCase('01DEBT')).thenAnswer((_) async => _collectionCase);

    await _pumpScreen(
      tester,
      input: const AddCaseReviewInput(
        customerDraft: CustomerDraft(name: 'New Traders', phone: '+252699999999', creditLimit: '1000.00'),
        debtDraft: _debtDraft,
      ),
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Customer & Debt'));
    await tester.pumpAndSettle();

    verify(() => mockCustomerRepository.createCustomer(name: 'New Traders', phone: '+252699999999', creditLimit: '1000.00'))
        .called(1);
    verify(() => mockDebtRepository.createDebt(customerId: '01NEW', amount: '500.00', dueDate: '2026-08-15', notes: null))
        .called(1);
    expect(find.text('Case Detail 01CASE'), findsOneWidget);
  });

  testWidgets('New Customer path: Debt creation failure surfaces the real error and a link to the created Customer',
      (tester) async {
    when(() => mockCustomerRepository.createCustomer(name: 'New Traders', phone: '+252699999999', creditLimit: '1000.00'))
        .thenAnswer((_) async => (customer: _newCustomer, warning: null));
    when(() => mockDebtRepository.createDebt(customerId: '01NEW', amount: '500.00', dueDate: '2026-08-15', notes: null))
        .thenThrow(const ApiException(message: 'Credit limit exceeded'));

    await _pumpScreen(
      tester,
      input: const AddCaseReviewInput(
        customerDraft: CustomerDraft(name: 'New Traders', phone: '+252699999999', creditLimit: '1000.00'),
        debtDraft: _debtDraft,
      ),
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Customer & Debt'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('The customer "New Traders" was created successfully'),
      findsOneWidget,
    );
    expect(find.textContaining('Credit limit exceeded'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Open Customer'));
    await tester.pumpAndSettle();

    expect(find.text('Customer Detail 01NEW'), findsOneWidget);
  });

  testWidgets('Case creation failure surfaces the real error and a link to the created Debt, no archive call',
      (tester) async {
    when(() => mockDebtRepository.createDebt(customerId: '01CUST', amount: '500.00', dueDate: '2026-08-15', notes: null))
        .thenAnswer((_) async => (debt: _debt, warning: null));
    when(() => mockDebtRepository.openCase('01DEBT')).thenThrow(const ApiException(message: 'Server error'));

    await _pumpScreen(
      tester,
      input: const AddCaseReviewInput(existingCustomer: _existingCustomer, debtDraft: _debtDraft),
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Debt'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Debt DBT-0001 was created successfully'), findsOneWidget);
    expect(find.textContaining('Server error'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Open Debt'));
    await tester.pumpAndSettle();

    expect(find.text('Debt Detail 01DEBT'), findsOneWidget);
  });
}
