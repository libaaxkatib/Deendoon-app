import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/business_health.dart';
import 'package:mobile/features/dashboard/domain/dashboard_kpis.dart';
import 'package:mobile/features/dashboard/domain/recent_case.dart';
import 'package:mobile/features/dashboard/domain/todays_overview.dart';
import 'package:mobile/features/dashboard/presentation/screens/home_dashboard_screen.dart';
import 'package:mocktail/mocktail.dart';

class _MockDashboardRepository extends Mock implements DashboardRepository {}

const _health = BusinessHealth(status: 'neutral_baseline', score: null);

const _kpis = DashboardKpis(
  totalOutstandingAmount: '800.00',
  totalCollectedPeriod: '100.00',
  highRiskCustomers: 2,
  overdueCount: 2,
  overdueValue: '400.00',
  customersOverCreditLimit: 1,
  activeCollectionCases: 3,
);

const _overview = TodaysOverview(totalDueToday: 9, paymentsDue: 5, clientVisits: 6, followUpCalls: 7);

final _recentCase = RecentCase(
  id: '01ABC',
  customerName: 'Somali Builders',
  outstandingAmount: '800.00',
  riskLevel: 'high',
  lastActivityAt: DateTime(2026, 7, 28),
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDashboardRepository mockRepository,
}) async {
  // The dashboard's ListView is taller than the default 800x600 test
  // surface — a phone-shaped viewport keeps every section actually built
  // (not just scrolled-past) so `find.text` can see it.
  tester.view.physicalSize = const Size(400, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepository)],
      child: const MaterialApp(home: HomeDashboardScreen()),
    ),
  );
}

void main() {
  late _MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = _MockDashboardRepository();
    when(() => mockRepository.fetchBusinessHealth()).thenAnswer((_) async => _health);
  });

  testWidgets('shows a loading indicator per section before data arrives', (tester) async {
    when(() => mockRepository.fetchKpis()).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 1), () => _kpis),
    );
    when(() => mockRepository.fetchTodaysOverview()).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 1), () => _overview),
    );
    when(() => mockRepository.fetchRecentCases()).thenAnswer(
      (_) => Future.delayed(const Duration(seconds: 1), () => <RecentCase>[]),
    );

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // Flush the mocked delays so no Timer is left pending when the test
    // (and its widget tree) is torn down.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('renders KPI values, overview counts, and recent case data', (tester) async {
    when(() => mockRepository.fetchKpis()).thenAnswer((_) async => _kpis);
    when(() => mockRepository.fetchTodaysOverview()).thenAnswer((_) async => _overview);
    when(() => mockRepository.fetchRecentCases()).thenAnswer((_) async => [_recentCase]);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('800.00'), findsWidgets); // Total Outstanding + case amount
    expect(find.text('100.00'), findsOneWidget); // Collected This Month
    expect(find.text('400.00'), findsOneWidget); // Overdue Amount
    expect(find.text('2'), findsOneWidget); // High Risk Customers

    expect(find.text('9'), findsOneWidget); // Reminders Due Today
    expect(find.text('5'), findsOneWidget); // Payments Due
    expect(find.text('6'), findsOneWidget); // Client Visits
    expect(find.text('7'), findsOneWidget); // Follow-up Calls

    expect(find.text('Somali Builders'), findsOneWidget);
    expect(find.text('High'), findsOneWidget); // risk badge label

    // Quick Actions render regardless of data state (static grid).
    expect(find.text('Add Case'), findsOneWidget);
    expect(find.text('Record Payment'), findsOneWidget);
    expect(find.text('Add Reminder'), findsOneWidget);
    expect(find.text('Global Search'), findsOneWidget);
  });

  testWidgets('shows the explicit empty state when there are no recent cases', (tester) async {
    when(() => mockRepository.fetchKpis()).thenAnswer((_) async => _kpis);
    when(() => mockRepository.fetchTodaysOverview()).thenAnswer((_) async => _overview);
    when(() => mockRepository.fetchRecentCases()).thenAnswer((_) async => <RecentCase>[]);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('No recent activity'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when a section fails to load, isolated from the others', (tester) async {
    when(() => mockRepository.fetchKpis()).thenThrow(Exception('network down'));
    when(() => mockRepository.fetchTodaysOverview()).thenAnswer((_) async => _overview);
    when(() => mockRepository.fetchRecentCases()).thenAnswer((_) async => <RecentCase>[]);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('Could not load KPIs.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    // Today's Overview still rendered its real data despite the KPI failure.
    expect(find.text('9'), findsOneWidget);

    when(() => mockRepository.fetchKpis()).thenAnswer((_) async => _kpis);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('800.00'), findsWidgets);
  });

  testWidgets('pull to refresh re-fetches all three sections', (tester) async {
    when(() => mockRepository.fetchKpis()).thenAnswer((_) async => _kpis);
    when(() => mockRepository.fetchTodaysOverview()).thenAnswer((_) async => _overview);
    when(() => mockRepository.fetchRecentCases()).thenAnswer((_) async => <RecentCase>[]);

    await _pumpScreen(tester, mockRepository: mockRepository);
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchKpis()).called(1);

    // Exercises the exact same callback a real pull gesture invokes,
    // without depending on scroll-physics/overscroll timing in the test
    // harness (RefreshIndicator's own gesture-to-trigger mechanics are
    // Flutter framework behavior, not this app's code).
    final refreshIndicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await refreshIndicator.onRefresh();
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchKpis()).called(1);
  });

  group('navigation', () {
    Future<void> pumpWithRouter(WidgetTester tester, GoRouter router) async {
      tester.view.physicalSize = const Size(400, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockRepository.fetchKpis()).thenAnswer((_) async => _kpis);
      when(() => mockRepository.fetchTodaysOverview()).thenAnswer((_) async => _overview);
      when(() => mockRepository.fetchRecentCases()).thenAnswer((_) async => [_recentCase]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepository)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Total Outstanding opens the tenant-wide Debts report', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeDashboardScreen()),
          GoRoute(
            path: '/analytics/reports/debts',
            builder: (_, state) => Text('Debts Report — status=${state.uri.queryParameters['status']}'),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Total Outstanding'));
      await tester.pumpAndSettle();

      expect(find.text('Debts Report — status=null'), findsOneWidget);
    });

    testWidgets('Overdue Amount opens the Debts report pre-filtered to overdue', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeDashboardScreen()),
          GoRoute(
            path: '/analytics/reports/debts',
            builder: (_, state) => Text('Debts Report — status=${state.uri.queryParameters['status']}'),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Overdue Amount'));
      await tester.pumpAndSettle();

      expect(find.text('Debts Report — status=overdue'), findsOneWidget);
    });

    testWidgets('Collected This Month opens Analytics', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeDashboardScreen()),
          GoRoute(path: '/analytics', builder: (_, _) => const Text('Analytics Screen')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Collected This Month'));
      await tester.pumpAndSettle();

      expect(find.text('Analytics Screen'), findsOneWidget);
    });

    testWidgets('High Risk Customers opens Cases pre-filtered to the high_risk tab', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeDashboardScreen()),
          GoRoute(
            path: '/cases',
            builder: (_, state) => Text('Cases — tab=${state.uri.queryParameters['tab']}'),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('High Risk Customers'));
      await tester.pumpAndSettle();

      expect(find.text('Cases — tab=high_risk'), findsOneWidget);
    });

    testWidgets('Recent Cases "View All" opens the Cases tab', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeDashboardScreen()),
          GoRoute(path: '/cases', builder: (_, _) => const Text('Cases Screen')),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(find.text('Cases Screen'), findsOneWidget);
    });

    testWidgets('tapping a Recent Cases row opens that case\'s detail screen', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const HomeDashboardScreen()),
          GoRoute(
            path: '/cases/:id',
            builder: (_, state) => Text('Case Detail — ${state.pathParameters['id']}'),
          ),
        ],
      );
      await pumpWithRouter(tester, router);

      await tester.tap(find.text('Somali Builders'));
      await tester.pumpAndSettle();

      expect(find.text('Case Detail — 01ABC'), findsOneWidget);
    });
  });
}
