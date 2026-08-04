import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/features/cases/domain/collection_case.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/debts/domain/debt_timeline.dart';
import 'package:mobile/features/debts/presentation/screens/debt_detail_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockDebtRepository extends Mock implements DebtRepository {}

class _MockCustomerRepository extends Mock implements CustomerRepository {}

const _customer = Customer(
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

const _debt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2026-07-01',
  debtStatus: 'overdue',
  remainingBalance: '400.00',
  recoveryStage: 3,
  notes: 'Call before 5pm',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDebtRepository debtRepository,
  required _MockCustomerRepository customerRepository,
}) async {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        debtRepositoryProvider.overrideWithValue(debtRepository),
        customerRepositoryProvider.overrideWithValue(customerRepository),
      ],
      child: const MaterialApp(home: DebtDetailScreen(debtId: '1')),
    ),
  );
}

void main() {
  late _MockDebtRepository mockDebtRepository;
  late _MockCustomerRepository mockCustomerRepository;

  setUp(() {
    mockDebtRepository = _MockDebtRepository();
    mockCustomerRepository = _MockCustomerRepository();

    when(() => mockDebtRepository.fetchDebt('1')).thenAnswer((_) async => _debt);
    when(() => mockCustomerRepository.fetchCustomer('01CUST')).thenAnswer((_) async => _customer);
    when(() => mockDebtRepository.fetchPayments('1')).thenAnswer((_) async => []);
    when(() => mockDebtRepository.fetchDocuments('1')).thenAnswer((_) async => []);
    when(() => mockDebtRepository.fetchTimeline('1'))
        .thenAnswer((_) async => const DebtTimeline(debtId: '1', stages: []));
  });

  testWidgets('renders debt summary, customer info, and keeps unavailable sections structurally present', (tester) async {
    await _pumpScreen(tester, debtRepository: mockDebtRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('DBT-0001'), findsWidgets); // AppBar title + summary card
    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('1000.00'), findsOneWidget);
    expect(find.text('400.00'), findsOneWidget);
    expect(find.text('Call before 5pm'), findsOneWidget);

    // Section titles remain in the layout even though their data isn't
    // available — per Sprint 12's explicit "keep the structure" rule.
    expect(find.text('Promise to Pay History'), findsOneWidget);
    expect(find.text('Related Case'), findsOneWidget);
    expect(find.textContaining('the backend has no endpoint to list past promises'), findsOneWidget);
    expect(find.textContaining('the backend has no endpoint to fetch an existing case'), findsOneWidget);

    expect(find.text('Record Payment'), findsOneWidget);
    expect(find.text('Promise to Pay'), findsOneWidget);
    expect(find.text('Open Case'), findsOneWidget);
  });

  testWidgets('renders real payment history and documents when present', (tester) async {
    when(() => mockDebtRepository.fetchPayments('1')).thenAnswer(
      (_) async => const [Payment(id: '1', debtId: '1', amount: '250.00', paymentDate: '2026-07-20', paymentMethod: 'cash')],
    );
    when(() => mockDebtRepository.fetchDocuments('1')).thenAnswer(
      (_) async => const [
        DocumentSummary(id: '1', documentType: 'receipt', referenceNumber: 'REC-0001', generatedAt: '2026-07-20', fileSize: 1024),
      ],
    );

    await _pumpScreen(tester, debtRepository: mockDebtRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('250.00'), findsOneWidget);
    expect(find.text('REC-0001'), findsOneWidget);
    expect(find.text('Receipt'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the debt fails to load', (tester) async {
    when(() => mockDebtRepository.fetchDebt('1')).thenThrow(Exception('network down'));

    await _pumpScreen(tester, debtRepository: mockDebtRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load this debt.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping Open Case calls the real endpoint, confirms, and navigates to the new Case Detail', (
    tester,
  ) async {
    const collectionCase = CollectionCase(
      id: '01CASE',
      debtId: '1',
      customerId: '01CUST',
      customerName: 'Somali Builders',
      outstandingAmount: '400.00',
      riskLevel: 'low',
      referenceNumber: 'COL-0001',
      assignedOfficerUserId: null,
      caseStatus: 'open',
      closureOutcome: null,
      lastActivityAt: '2026-08-01T10:00:00.000000Z',
      createdAt: '2026-08-01T10:00:00.000000Z',
      closedAt: null,
    );
    when(() => mockDebtRepository.openCase('1')).thenAnswer((_) async => collectionCase);

    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DebtDetailScreen(debtId: '1')),
        GoRoute(path: '/cases/:id', builder: (_, state) => Text('Case Detail Screen ${state.pathParameters['id']}')),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debtRepositoryProvider.overrideWithValue(mockDebtRepository),
          customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Case'));
    await tester.pumpAndSettle();

    verify(() => mockDebtRepository.openCase('1')).called(1);
    expect(find.text('Case Detail Screen 01CASE'), findsOneWidget);
  });

  testWidgets('Edit opens the Edit Debt screen', (tester) async {
    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DebtDetailScreen(debtId: '1')),
        GoRoute(path: '/debts/1/edit', builder: (_, _) => const Text('Edit Debt Screen')),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debtRepositoryProvider.overrideWithValue(mockDebtRepository),
          customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit Debt'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Debt Screen'), findsOneWidget);
  });

  testWidgets('Generate Statement calls the real endpoint and shows a success snackbar', (tester) async {
    const statement = DocumentSummary(
      id: '2',
      documentType: 'statement',
      referenceNumber: 'STM-0001',
      generatedAt: '2026-08-01T00:00:00.000000Z',
      fileSize: 3000,
    );
    when(() => mockDebtRepository.generateStatement('1')).thenAnswer((_) async => statement);

    await _pumpScreen(tester, debtRepository: mockDebtRepository, customerRepository: mockCustomerRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Generate Statement'));
    await tester.pumpAndSettle();

    verify(() => mockDebtRepository.generateStatement('1')).called(1);
    expect(find.text('Statement generated successfully'), findsOneWidget);
  });

  group('Log Reminder', () {
    testWidgets('Log WhatsApp opens the sheet and submits the entered details', (tester) async {
      when(() => mockDebtRepository.logWhatsAppReminder(debtId: '1', details: 'Sent via WhatsApp'))
          .thenAnswer((_) async => _debt);

      await _pumpScreen(tester, debtRepository: mockDebtRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log WhatsApp'));
      await tester.pumpAndSettle();

      expect(find.text('Log WhatsApp Reminder'), findsWidgets);
      await tester.enterText(find.widgetWithText(TextField, 'Details (optional)'), 'Sent via WhatsApp');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log WhatsApp Reminder'));
      await tester.pumpAndSettle();

      verify(() => mockDebtRepository.logWhatsAppReminder(debtId: '1', details: 'Sent via WhatsApp')).called(1);
      // Follow-up Timeline and the debt itself both refresh after a
      // successful log — fetchTimeline/fetchDebt are called again beyond
      // their initial load.
      verify(() => mockDebtRepository.fetchTimeline('1')).called(2);
      verify(() => mockDebtRepository.fetchDebt('1')).called(2);
    });

    testWidgets('Log SMS submits with no details when the field is left empty', (tester) async {
      when(() => mockDebtRepository.logSmsReminder(debtId: '1', details: null)).thenAnswer((_) async => _debt);

      await _pumpScreen(tester, debtRepository: mockDebtRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log SMS'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Log SMS Reminder'));
      await tester.pumpAndSettle();

      verify(() => mockDebtRepository.logSmsReminder(debtId: '1', details: null)).called(1);
    });

    testWidgets('Log Call submits with the entered outcome', (tester) async {
      when(() => mockDebtRepository.logCallReminder(debtId: '1', details: 'No answer')).thenAnswer((_) async => _debt);

      await _pumpScreen(tester, debtRepository: mockDebtRepository, customerRepository: mockCustomerRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Call'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Details (optional)'), 'No answer');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log Call'));
      await tester.pumpAndSettle();

      verify(() => mockDebtRepository.logCallReminder(debtId: '1', details: 'No answer')).called(1);
    });
  });
}
