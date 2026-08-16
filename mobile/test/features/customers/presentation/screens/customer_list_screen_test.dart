import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/customers/domain/customer_page.dart';
import 'package:mobile/features/customers/presentation/providers/customer_list_provider.dart';
import 'package:mobile/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  SomaliMaterialLocalizationsDelegate(),
  SomaliCupertinoLocalizationsDelegate(),
];

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

const _archivedCustomer = Customer(
  id: '2',
  name: 'Old Traders',
  phone: '+252699999999',
  customerStatus: 'active',
  creditLimit: '1000.00',
  outstandingBalance: '0.00',
  remainingCredit: '1000.00',
  riskLevel: null,
  creditScore: null,
  creditScoreBand: null,
  archivedAt: '2026-06-01T00:00:00.000000Z',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockCustomerRepository mockRepository,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _localizationsDelegates,
        home: CustomerListScreen(),
      ),
    ),
  );
}

Future<void> _pumpScreenWithRouter(
  WidgetTester tester, {
  required _MockCustomerRepository mockRepository,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const CustomerListScreen()),
      GoRoute(
        path: '/customers/new',
        builder: (_, _) => const Text('Add Customer Screen'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [customerRepositoryProvider.overrideWithValue(mockRepository)],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _localizationsDelegates,
      ),
    ),
  );
}

void main() {
  late _MockCustomerRepository mockRepository;

  setUp(() {
    mockRepository = _MockCustomerRepository();
  });

  testWidgets('shows a loading indicator before data arrives', (tester) async {
    when(
      () => mockRepository.fetchCustomers(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
      ),
    ).thenAnswer(
      (_) => Future.delayed(
        const Duration(seconds: 1),
        () => const CustomerPage(
          customers: [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      ),
    );

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('renders customer cards with the real backend fields', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchCustomers(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
      ),
    ).thenAnswer(
      (_) async => const CustomerPage(
        customers: [_customer],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      ),
    );

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('+252612345678'), findsOneWidget);
    expect(find.text('800.00'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Good Standing'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no customers', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchCustomers(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
      ),
    ).thenAnswer(
      (_) async => const CustomerPage(
        customers: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      ),
    );

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No customers yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (
    tester,
  ) async {
    when(
      () => mockRepository.fetchCustomers(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
      ),
    ).thenThrow(Exception('network down'));

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load customers.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'typing in the search field triggers a real API call with the query',
    (tester) async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: 'somali',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      await _pumpScreen(tester, mockRepository: mockRepository);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'somali');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: 'somali',
          status: null,
          riskLevel: null,
        ),
      ).called(1);
    },
  );

  testWidgets('the FAB opens the Add Customer screen', (tester) async {
    when(
      () => mockRepository.fetchCustomers(
        page: 1,
        search: '',
        status: null,
        riskLevel: null,
      ),
    ).thenAnswer(
      (_) async => const CustomerPage(
        customers: [_customer],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      ),
    );

    await _pumpScreenWithRouter(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Customer Screen'), findsOneWidget);
  });

  testWidgets(
    'the Show Archived chip includes archived customers via a real query param',
    (tester) async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customer, _archivedCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 2,
        ),
      );

      await _pumpScreen(tester, mockRepository: mockRepository);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Show Archived'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
          includeArchived: true,
        ),
      ).called(1);
      expect(find.text('Old Traders'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Restore'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Restore on an archived customer calls the real endpoint',
    (tester) async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_archivedCustomer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );
      when(
        () => mockRepository.restoreCustomer('2'),
      ).thenAnswer((_) async => _archivedCustomer);

      await _pumpScreen(tester, mockRepository: mockRepository);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Show Archived'));
      await tester.pumpAndSettle();

      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [],
          currentPage: 1,
          lastPage: 1,
          total: 0,
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Restore'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.restoreCustomer('2')).called(1);
      expect(find.text('Customer restored successfully'), findsOneWidget);
    },
  );

  testWidgets(
    'Mobile Fix #12: a failed load-more shows the retry state; retry calls loadMore() and returns to normal on success',
    (tester) async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customer],
          currentPage: 1,
          lastPage: 2,
          total: 2,
        ),
      );
      when(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenThrow(Exception('network error'));

      final container = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _localizationsDelegates,
            home: CustomerListScreen(),
          ),
        ),
      );
      // Not pumpAndSettle: with hasMore true the footer's steady-state
      // spinner is an indeterminate CircularProgressIndicator, which
      // animates forever and would make pumpAndSettle time out.
      await tester.pump();
      await tester.pump();

      // Simulates the scroll-triggered loadMore() directly rather than a
      // real drag gesture — this test targets the failure/retry UI, not
      // the scroll-threshold trigger itself (untouched by Fix #12).
      await container.read(customerListProvider.notifier).loadMore();
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load more. Tap to retry."), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);

      when(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_archivedCustomer],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load more. Tap to retry."), findsNothing);
      expect(find.text('Old Traders'), findsOneWidget);
      verify(
        () => mockRepository.fetchCustomers(
          page: 2,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).called(2);
    },
  );

  testWidgets(
    'selection mode: title changes, FAB is hidden, and tapping a card pops with the Customer',
    (tester) async {
      when(
        () => mockRepository.fetchCustomers(
          page: 1,
          search: '',
          status: null,
          riskLevel: null,
        ),
      ).thenAnswer(
        (_) async => const CustomerPage(
          customers: [_customer],
          currentPage: 1,
          lastPage: 1,
          total: 1,
        ),
      );

      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Customer? popped;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  popped = await context.push<Customer>('/select');
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
          GoRoute(
            path: '/select',
            builder: (_, _) => const CustomerListScreen(selectionMode: true),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: _localizationsDelegates,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Select Customer'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('Somali Builders'));
      await tester.pumpAndSettle();

      expect(popped, _customer);
    },
  );
}
