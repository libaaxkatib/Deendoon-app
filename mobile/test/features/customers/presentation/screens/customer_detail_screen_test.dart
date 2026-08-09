import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/document_summary.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/core/models/payment.dart';
import 'package:mobile/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockCustomerRepository extends Mock implements CustomerRepository {}

const _customer = Customer(
  id: '1',
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

const _readOnlyCustomer = Customer(
  id: '1',
  name: 'Somali Builders',
  phone: '+252612345678',
  customerStatus: 'good_standing',
  creditLimit: '5000.00',
  outstandingBalance: '800.00',
  remainingCredit: '4200.00',
  riskLevel: 'low',
  creditScore: 720,
  creditScoreBand: 'good',
  isReadOnly: true,
  archivedAt: null,
);

final _payment = Payment(
  id: '01PAY',
  debtId: '01DEBT',
  amount: '250.00',
  paymentDate: '2026-07-20',
  paymentMethod: 'cash',
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockCustomerRepository mockRepository}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
      child: const MaterialApp(home: CustomerDetailScreen(customerId: '1')),
    ),
  );
}

void main() {
  late _MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = _MockCustomerRepository();
  });

  testWidgets('renders customer info and recent payments from the real backend fields', (tester) async {
    when(() => mockRepository.fetchCustomer('1')).thenAnswer((_) async => _customer);
    when(() => mockRepository.fetchPayments('1')).thenAnswer((_) async => [_payment]);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Somali Builders'), findsWidgets); // AppBar title + info card
    expect(find.text('+252612345678'), findsOneWidget);
    expect(find.text('800.00'), findsOneWidget);
    expect(find.text('5000.00'), findsOneWidget);
    expect(find.text('4200.00'), findsOneWidget);
    expect(find.text('720 (good)'), findsOneWidget);
    expect(find.text('250.00'), findsOneWidget);
    expect(find.text('cash'), findsOneWidget);

    // Active Cases / Recent Follow-ups are deliberately not rendered — no
    // backend endpoint scopes either to a single customer.
    expect(find.textContaining('Active Cases'), findsNothing);
    expect(find.textContaining('Follow-up'), findsNothing);
  });

  testWidgets('shows the explicit empty state when there are no payments', (tester) async {
    when(() => mockRepository.fetchCustomer('1')).thenAnswer((_) async => _customer);
    when(() => mockRepository.fetchPayments('1')).thenAnswer((_) async => []);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No recent payments'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the customer fails to load', (tester) async {
    when(() => mockRepository.fetchCustomer('1')).thenThrow(Exception('network down'));
    when(() => mockRepository.fetchPayments('1')).thenAnswer((_) async => []);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load this customer.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  group('actions (with a real router)', () {
    Future<void> pumpWithRouter(WidgetTester tester, GoRouter router) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockRepository.fetchCustomer('1')).thenAnswer((_) async => _customer);
      when(() => mockRepository.fetchPayments('1')).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Edit opens the Edit Customer screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
          GoRoute(path: '/customers/1/edit', builder: (_, _) => const Text('Edit Customer Screen')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.byTooltip('Edit Customer'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Customer Screen'), findsOneWidget);
    });

    testWidgets('Documents opens the customer-scoped Documents screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
          GoRoute(path: '/customers/1/documents', builder: (_, _) => const Text('Customer Documents Screen')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Documents'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Documents Screen'), findsOneWidget);
    });

    testWidgets('Cases opens the customer-scoped Cases screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
          GoRoute(path: '/customers/1/cases', builder: (_, _) => const Text('Customer Cases Screen')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cases'));
      await tester.pumpAndSettle();

      expect(find.text('Customer Cases Screen'), findsOneWidget);
    });

    testWidgets('Attachments opens the customer-scoped Attachments screen with canUpload true', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
          GoRoute(
            path: '/customers/1/attachments',
            builder: (_, state) => Text('Attachments Screen — canUpload=${state.extra}'),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Attachments'));
      await tester.pumpAndSettle();

      expect(find.text('Attachments Screen — canUpload=true'), findsOneWidget);
    });

    testWidgets('Archive asks for confirmation, calls the real endpoint, and pops back on success', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Customer List Screen'))),
          GoRoute(path: '/detail', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
        ],
      );
      when(() => mockRepository.archiveCustomer('1')).thenAnswer((_) async {});
      await pumpWithRouter(tester, router);
      router.push('/detail');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Archive Customer'));
      await tester.pumpAndSettle();

      expect(find.text('This customer will no longer appear in the default list. This can be undone later.'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.archiveCustomer('1')).called(1);
      expect(find.text('Customer List Screen'), findsOneWidget);
      expect(find.text('Customer archived successfully'), findsOneWidget);
    });

    testWidgets('Archive does nothing when the confirmation dialog is cancelled', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.byTooltip('Archive Customer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => mockRepository.archiveCustomer(any()));
      expect(find.byType(CustomerDetailScreen), findsOneWidget);
    });

    testWidgets('editing the Credit Limit opens the sheet and calls the dedicated endpoint', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
        ],
      );
      when(() => mockRepository.updateCreditLimit(id: '1', creditLimit: '6000.00')).thenAnswer((_) async => _customer);
      await pumpWithRouter(tester, router);

      await tester.tap(find.byTooltip('Edit Credit Limit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Credit Limit'), '6000.00');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateCreditLimit(id: '1', creditLimit: '6000.00')).called(1);
    });

    testWidgets('changing the Customer Status opens the sheet and calls the dedicated endpoint', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
        ],
      );
      when(() => mockRepository.updateStatus(id: '1', customerStatus: 'high_risk')).thenAnswer((_) async => _customer);
      await pumpWithRouter(tester, router);

      await tester.tap(find.byTooltip('Change Customer Status'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(RadioListTile<String>, 'High Risk'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.updateStatus(id: '1', customerStatus: 'high_risk')).called(1);
    });

    testWidgets('Generate Statement calls the real endpoint and shows a success snackbar', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
        ],
      );
      const statement = DocumentSummary(
        id: '1',
        documentType: 'statement',
        referenceNumber: 'STM-0001',
        generatedAt: '2026-08-01T00:00:00.000000Z',
        fileSize: 3000,
      );
      when(() => mockRepository.generateStatement('1')).thenAnswer((_) async => statement);
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Generate Statement'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.generateStatement('1')).called(1);
      expect(find.text('Statement generated successfully'), findsOneWidget);
    });

    testWidgets(
      'a read-only customer shows the banner, disables Edit/Archive/Generate Statement/Credit Limit edit',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
            GoRoute(path: '/account/subscription', builder: (_, _) => const Text('Subscription Screen')),
          ],
        );
        tester.view.physicalSize = const Size(400, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        when(() => mockRepository.fetchCustomer('1')).thenAnswer((_) async => _readOnlyCustomer);
        when(() => mockRepository.fetchPayments('1')).thenAnswer((_) async => []);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Read-only Customer'), findsOneWidget);

        final editButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.edit_outlined));
        expect(editButton.onPressed, isNull);
        final archiveButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.archive_outlined));
        expect(archiveButton.onPressed, isNull);

        expect(find.widgetWithText(OutlinedButton, 'Generate Statement'), findsOneWidget);
        final generateStatementButton =
            tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Generate Statement'));
        expect(generateStatementButton.onPressed, isNull);

        // Credit Limit's and Customer Status's edit icons are both hidden
        // entirely when their callbacks are null.
        expect(find.byTooltip('Edit Credit Limit'), findsNothing);
        expect(find.byTooltip('Change Customer Status'), findsNothing);

        await tester.tap(find.widgetWithText(OutlinedButton, 'Upgrade Plan'));
        await tester.pumpAndSettle();

        expect(find.text('Subscription Screen'), findsOneWidget);
      },
    );

    testWidgets('a read-only customer navigates to Attachments with canUpload false', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const CustomerDetailScreen(customerId: '1')),
          GoRoute(
            path: '/customers/1/attachments',
            builder: (_, state) => Text('Attachments Screen — canUpload=${state.extra}'),
          ),
        ],
      );
      when(() => mockRepository.fetchCustomer('1')).thenAnswer((_) async => _readOnlyCustomer);
      when(() => mockRepository.fetchPayments('1')).thenAnswer((_) async => []);
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Attachments'));
      await tester.pumpAndSettle();

      expect(find.text('Attachments Screen — canUpload=false'), findsOneWidget);
    });
  });
}
