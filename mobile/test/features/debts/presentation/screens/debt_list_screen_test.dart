import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/somali_fallback_delegates.dart';
import 'package:mobile/features/customers/data/customer_repository.dart';
import 'package:mobile/features/customers/domain/customer.dart';
import 'package:mobile/features/debts/data/debt_repository.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mobile/features/debts/domain/debt_page.dart';
import 'package:mobile/features/debts/presentation/providers/debt_list_provider.dart';
import 'package:mobile/features/debts/presentation/screens/debt_list_screen.dart';
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
  riskLevel: 'high',
  creditScore: 720,
  creditScoreBand: 'good',
  archivedAt: null,
);

const _debt = Debt(
  id: '1',
  customerId: '01CUST',
  referenceNumber: 'DBT-0001',
  amount: '1000.00',
  dueDate: '2020-01-01',
  debtStatus: 'overdue',
  remainingBalance: '400.00',
  recoveryStage: 3,
  notes: null,
);

const _archivedDebt = Debt(
  id: '2',
  customerId: '01CUST',
  referenceNumber: 'DBT-0002',
  amount: '500.00',
  dueDate: '2020-02-01',
  debtStatus: 'pending',
  remainingBalance: '500.00',
  recoveryStage: 1,
  notes: null,
  archivedAt: '2026-06-01T00:00:00.000000Z',
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDebtRepository debtRepository,
  required _MockCustomerRepository customerRepository,
}) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        debtRepositoryProvider.overrideWithValue(debtRepository),
        customerRepositoryProvider.overrideWithValue(customerRepository),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: _localizationsDelegates,
        home: DebtListScreen(customerId: '01CUST'),
      ),
    ),
  );
}

void main() {
  late _MockDebtRepository mockDebtRepository;
  late _MockCustomerRepository mockCustomerRepository;

  setUp(() {
    mockDebtRepository = _MockDebtRepository();
    mockCustomerRepository = _MockCustomerRepository();
    when(
      () => mockCustomerRepository.fetchCustomer('01CUST'),
    ).thenAnswer((_) async => _customer);
  });

  testWidgets('renders debt cards with real fields and days overdue', (
    tester,
  ) async {
    when(
      () => mockDebtRepository.fetchDebts(
        page: 1,
        customerId: '01CUST',
        status: null,
        dateFrom: null,
        dateTo: null,
      ),
    ).thenAnswer(
      (_) async =>
          const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1),
    );

    await _pumpScreen(
      tester,
      debtRepository: mockDebtRepository,
      customerRepository: mockCustomerRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('DBT-0001'), findsOneWidget);
    expect(find.text('1000.00'), findsOneWidget);
    expect(find.text('400.00'), findsOneWidget);
    expect(find.textContaining('overdue'), findsWidgets);
    // Risk level comes from the parent customer, not the debt itself.
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no debts', (
    tester,
  ) async {
    when(
      () => mockDebtRepository.fetchDebts(
        page: 1,
        customerId: '01CUST',
        status: null,
        dateFrom: null,
        dateTo: null,
      ),
    ).thenAnswer(
      (_) async =>
          const DebtPage(debts: [], currentPage: 1, lastPage: 1, total: 0),
    );

    await _pumpScreen(
      tester,
      debtRepository: mockDebtRepository,
      customerRepository: mockCustomerRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('No debts yet'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when the list fails to load', (
    tester,
  ) async {
    when(
      () => mockDebtRepository.fetchDebts(
        page: 1,
        customerId: '01CUST',
        status: null,
        dateFrom: null,
        dateTo: null,
      ),
    ).thenThrow(Exception('network down'));

    await _pumpScreen(
      tester,
      debtRepository: mockDebtRepository,
      customerRepository: mockCustomerRepository,
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load debts.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets(
    'tapping a status filter chip triggers a real API call with that status',
    (tester) async {
      // "Overdue" is used here (not the later "Paid" chip) since the filter
      // row scrolls horizontally — only the chips visible without scrolling
      // can be tapped directly in a widget test.
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
      when(
        () => mockDebtRepository.fetchDebts(
          page: 1,
          customerId: '01CUST',
          status: 'overdue',
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async =>
            const DebtPage(debts: [], currentPage: 1, lastPage: 1, total: 0),
      );

      await _pumpScreen(
        tester,
        debtRepository: mockDebtRepository,
        customerRepository: mockCustomerRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Overdue'));
      await tester.pumpAndSettle();

      verify(
        () => mockDebtRepository.fetchDebts(
          page: 1,
          customerId: '01CUST',
          status: 'overdue',
          dateFrom: null,
          dateTo: null,
        ),
      ).called(1);
      expect(find.text('No debts with this status'), findsOneWidget);
    },
  );

  testWidgets(
    'the Show Archived chip includes archived debts via a real query param',
    (tester) async {
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
      when(
        () => mockDebtRepository.fetchDebts(
          page: 1,
          customerId: '01CUST',
          status: null,
          dateFrom: null,
          dateTo: null,
          includeArchived: true,
        ),
      ).thenAnswer(
        (_) async => const DebtPage(
          debts: [_debt, _archivedDebt],
          currentPage: 1,
          lastPage: 1,
          total: 2,
        ),
      );

      await _pumpScreen(
        tester,
        debtRepository: mockDebtRepository,
        customerRepository: mockCustomerRepository,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Show Archived'));
      await tester.pumpAndSettle();

      verify(
        () => mockDebtRepository.fetchDebts(
          page: 1,
          customerId: '01CUST',
          status: null,
          dateFrom: null,
          dateTo: null,
          includeArchived: true,
        ),
      ).called(1);
      expect(find.text('DBT-0002'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Restore'), findsOneWidget);
    },
  );

  testWidgets('tapping Restore on an archived debt calls the real endpoint', (
    tester,
  ) async {
    when(
      () => mockDebtRepository.fetchDebts(
        page: 1,
        customerId: '01CUST',
        status: null,
        dateFrom: null,
        dateTo: null,
        includeArchived: true,
      ),
    ).thenAnswer(
      (_) async => const DebtPage(
        debts: [_archivedDebt],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      ),
    );
    when(
      () => mockDebtRepository.restoreDebt('2'),
    ).thenAnswer((_) async => _archivedDebt);

    await _pumpScreen(
      tester,
      debtRepository: mockDebtRepository,
      customerRepository: mockCustomerRepository,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Show Archived'));
    await tester.pumpAndSettle();

    when(
      () => mockDebtRepository.fetchDebts(
        page: 1,
        customerId: '01CUST',
        status: null,
        dateFrom: null,
        dateTo: null,
      ),
    ).thenAnswer(
      (_) async =>
          const DebtPage(debts: [], currentPage: 1, lastPage: 1, total: 0),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Restore'));
    await tester.pumpAndSettle();

    verify(() => mockDebtRepository.restoreDebt('2')).called(1);
    expect(find.text('Debt restored successfully'), findsOneWidget);

    // Mobile Fix #14 regression: the list must actually rebuild with the
    // fresh (now-empty) data DebtActions.restore()'s invalidate() causes,
    // not silently fall into the load-error/retry state — which is exactly
    // what the pre-existing `late final customerId` bug produced, and what
    // this test previously never asserted on.
    expect(find.text('No debts yet'), findsOneWidget);
    expect(find.text('Could not load debts.'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Restore'), findsNothing);
  });

  testWidgets(
    'Mobile Fix #12: a failed load-more shows the retry state and a retry appends the next page without losing existing records',
    (tester) async {
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
          lastPage: 2,
          total: 2,
        ),
      );
      when(
        () => mockDebtRepository.fetchDebts(
          page: 2,
          customerId: '01CUST',
          status: null,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenThrow(Exception('network error'));

      final container = ProviderContainer(
        overrides: [
          debtRepositoryProvider.overrideWithValue(mockDebtRepository),
          customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
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
            home: DebtListScreen(customerId: '01CUST'),
          ),
        ),
      );
      // Not pumpAndSettle: with hasMore true the footer's steady-state
      // spinner is an indeterminate CircularProgressIndicator, which
      // animates forever and would make pumpAndSettle time out.
      await tester.pump();
      await tester.pump();

      await container.read(debtListProvider('01CUST').notifier).loadMore();
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load more. Tap to retry."), findsOneWidget);
      expect(find.text('DBT-0001'), findsOneWidget);

      when(
        () => mockDebtRepository.fetchDebts(
          page: 2,
          customerId: '01CUST',
          status: null,
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer(
        (_) async => const DebtPage(
          debts: [_archivedDebt],
          currentPage: 2,
          lastPage: 2,
          total: 2,
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load more. Tap to retry."), findsNothing);
      expect(find.text('DBT-0001'), findsOneWidget);
      expect(find.text('DBT-0002'), findsOneWidget);
      verify(
        () => mockDebtRepository.fetchDebts(
          page: 2,
          customerId: '01CUST',
          status: null,
          dateFrom: null,
          dateTo: null,
        ),
      ).called(2);
    },
  );

  testWidgets('the FAB opens the Add Debt screen', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockDebtRepository.fetchDebts(
        page: 1,
        customerId: '01CUST',
        status: null,
        dateFrom: null,
        dateTo: null,
      ),
    ).thenAnswer(
      (_) async =>
          const DebtPage(debts: [_debt], currentPage: 1, lastPage: 1, total: 1),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const DebtListScreen(customerId: '01CUST'),
        ),
        GoRoute(
          path: '/customers/01CUST/debts/new',
          builder: (_, _) => const Text('Add Debt Screen'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debtRepositoryProvider.overrideWithValue(mockDebtRepository),
          customerRepositoryProvider.overrideWithValue(mockCustomerRepository),
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

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Debt Screen'), findsOneWidget);
  });

  testWidgets(
    'selection mode: title changes, FAB is hidden, and tapping a card pops with the Debt',
    (tester) async {
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

      tester.view.physicalSize = const Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Debt? popped;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  popped = await context.push<Debt>('/select');
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
          GoRoute(
            path: '/select',
            builder: (_, _) =>
                const DebtListScreen(customerId: '01CUST', selectionMode: true),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            debtRepositoryProvider.overrideWithValue(mockDebtRepository),
            customerRepositoryProvider.overrideWithValue(
              mockCustomerRepository,
            ),
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

      expect(find.text('Select Debt'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);

      await tester.tap(find.text('DBT-0001'));
      await tester.pumpAndSettle();

      expect(popped, _debt);
    },
  );
}
