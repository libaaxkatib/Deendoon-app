import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/cases/data/collection_case_repository.dart';
import 'package:mobile/features/cases/domain/case_history.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/cases/presentation/screens/case_detail_screen.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mocktail/mocktail.dart';

class _MockCollectionCaseRepository extends Mock implements CollectionCaseRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

class _MockDebtRepository extends Mock implements DebtRepository {}

const _customer = Customer(
  id: '01CUST',
  name: 'Somali Builders',
  phone: '+252612345678',
  customerStatus: 'high_risk',
  creditLimit: '5000.00',
  outstandingBalance: '4467.40',
  remainingCredit: '532.60',
  riskLevel: 'high',
  creditScore: 480,
  creditScoreBand: 'poor',
);

const _debt = Debt(
  id: '01DEBT',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '4467.40',
  dueDate: '2026-08-26',
  debtStatus: 'pending',
  remainingBalance: '4467.40',
  recoveryStage: 5,
  notes: null,
);

const _openCase = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: null,
  caseStatus: 'open',
  closureOutcome: null,
  lastActivityAt: '2026-07-28T10:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: null,
);

const _closedCase = CollectionCase(
  id: '01CASE',
  debtId: '01DEBT',
  customerId: '01CUST',
  customerName: 'Somali Builders',
  outstandingAmount: '4467.40',
  riskLevel: 'high',
  referenceNumber: 'COL-0001',
  assignedOfficerUserId: '01OFFICER',
  caseStatus: 'closed',
  closureOutcome: 'Paid in full',
  lastActivityAt: '2026-07-28T12:00:00.000000Z',
  createdAt: '2026-07-01T10:00:00.000000Z',
  closedAt: '2026-07-28T12:00:00.000000Z',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockCollectionCaseRepository caseRepository,
  required _MockCustomerRepository customerRepository,
  required _MockDebtRepository debtRepository,
}) async {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        collectionCaseRepositoryProvider.overrideWithValue(caseRepository),
        customerRepositoryProvider.overrideWithValue(customerRepository),
        debtRepositoryProvider.overrideWithValue(debtRepository),
      ],
      child: const MaterialApp(home: CaseDetailScreen(caseId: '01CASE')),
    ),
  );
}

void main() {
  late _MockCollectionCaseRepository mockCaseRepository;
  late _MockCustomerRepository mockCustomerRepository;
  late _MockDebtRepository mockDebtRepository;

  setUp(() {
    mockCaseRepository = _MockCollectionCaseRepository();
    mockCustomerRepository = _MockCustomerRepository();
    mockDebtRepository = _MockDebtRepository();

    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);
    when(() => mockDebtRepository.fetchDebt('01DEBT')).thenAnswer((_) async => _debt);
    when(() => mockDebtRepository.fetchPayments('01DEBT')).thenAnswer((_) async => []);
    when(() => mockDebtRepository.fetchDocuments('01DEBT')).thenAnswer((_) async => []);
    when(() => mockCaseRepository.fetchHistory('01CASE'))
        .thenAnswer((_) async => const CaseHistory(collectionCaseId: '01CASE', entries: []));
  });

  testWidgets('renders case summary, customer, debt, and collection stage from real data', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCase);

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('COL-0001'), findsWidgets); // AppBar title + Case Summary card
    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('Stage 5 of 6'), findsOneWidget);
    expect(find.text('Unassigned'), findsOneWidget);

    // Notes has no dedicated backend field/endpoint — kept structurally
    // present with an honest reason, per this sprint's explicit rule.
    expect(find.text('Notes'), findsOneWidget);
    expect(find.textContaining('no dedicated Notes field'), findsOneWidget);

    expect(find.text('Add Follow-up'), findsOneWidget);
    expect(find.text('Mark Contacted'), findsOneWidget);
    expect(find.text('Record Visit'), findsOneWidget);
    expect(find.text('Promise to Pay'), findsOneWidget);
    expect(find.text('Close Case'), findsOneWidget);
  });

  testWidgets('a closed case hides action buttons and shows an explanatory note instead', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _closedCase);

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Follow-up'), findsNothing);
    expect(find.text('Close Case'), findsNothing);
    expect(find.textContaining('This case is closed'), findsOneWidget);
    expect(find.text('Officer 01OFFICER'), findsOneWidget);
    expect(find.text('Paid in full'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the case fails to load', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenThrow(Exception('network down'));

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load this case.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('submitting Close Case calls the real endpoint with the entered outcome', (tester) async {
    when(() => mockCaseRepository.fetchCase('01CASE')).thenAnswer((_) async => _openCase);
    when(() => mockCaseRepository.close(caseId: '01CASE', closureOutcome: 'Paid in full'))
        .thenAnswer((_) async => _closedCase);

    await _pumpScreen(
      tester,
      caseRepository: mockCaseRepository,
      customerRepository: mockCustomerRepository,
      debtRepository: mockDebtRepository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Close Case'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Paid in full');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Close Case'));
    await tester.pumpAndSettle();

    verify(() => mockCaseRepository.close(caseId: '01CASE', closureOutcome: 'Paid in full')).called(1);
  });
}
