import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_document.dart';
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
        DebtDocument(id: '1', documentType: 'receipt', referenceNumber: 'REC-0001', generatedAt: '2026-07-20', fileSize: 1024),
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

  testWidgets('tapping Open Case calls the real endpoint, confirms, and navigates to the Case List', (tester) async {
    when(() => mockDebtRepository.openCase('1')).thenAnswer((_) async {});

    tester.view.physicalSize = const Size(400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DebtDetailScreen(debtId: '1')),
        GoRoute(path: '/cases', builder: (_, _) => const Scaffold(body: Text('Case List Screen'))),
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
    expect(find.text('Case List Screen'), findsOneWidget);
  });
}
