import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/business_health.dart';
import 'package:mobile/features/dashboard/domain/dashboard_kpis.dart';
import 'package:mobile/features/dashboard/domain/recent_case.dart';
import 'package:mobile/features/dashboard/domain/todays_overview.dart';
import 'package:mobile/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:mobile/features/dashboard/presentation/providers/kpi_period_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockDashboardRepository extends Mock implements DashboardRepository {}

const _health = BusinessHealth(status: 'healthy', score: 90);

const _kpis = DashboardKpis(
  totalOutstandingAmount: '800.00',
  totalCollectedPeriod: '100.00',
  highRiskCustomers: 2,
  overdueCount: 2,
  overdueValue: '400.00',
  customersOverCreditLimit: 1,
  activeCollectionCases: 3,
);

const _overview = TodaysOverview(
  totalDueToday: 4,
  paymentsDue: 1,
  clientVisits: 2,
  followUpCalls: 1,
);

void main() {
  late _MockDashboardRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockDashboardRepository();
    container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'each provider resolves independently — one failure does not affect the others',
    () async {
      when(
        () => mockRepository.fetchBusinessHealth(),
      ).thenAnswer((_) async => _health);
      when(
        () => mockRepository.fetchKpis(
          period: 'this_month',
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer((_) async => _kpis);
      when(
        () => mockRepository.fetchTodaysOverview(),
      ).thenThrow(Exception('network down'));
      when(
        () => mockRepository.fetchRecentCases(),
      ).thenAnswer((_) async => <RecentCase>[]);

      final health = await container.read(businessHealthProvider.future);
      expect(health, _health);

      final kpis = await container.read(dashboardKpisProvider.future);
      expect(kpis, _kpis);

      await expectLater(
        container.read(todaysOverviewProvider.future),
        throwsException,
      );

      final cases = await container.read(recentCasesProvider.future);
      expect(cases, isEmpty);

      // Confirms the failure is isolated to its own AsyncValue, not
      // propagated to sibling providers.
      expect(
        container.read(businessHealthProvider),
        isA<AsyncData<BusinessHealth>>(),
      );
      expect(
        container.read(dashboardKpisProvider),
        isA<AsyncData<DashboardKpis>>(),
      );
      expect(
        container.read(todaysOverviewProvider),
        isA<AsyncError<TodaysOverview>>(),
      );
    },
  );

  test('refreshDashboard re-fetches all four after invalidation', () async {
    var healthCallCount = 0;
    when(() => mockRepository.fetchBusinessHealth()).thenAnswer((_) async {
      healthCallCount++;
      return _health;
    });
    var kpisCallCount = 0;
    when(
      () => mockRepository.fetchKpis(
        period: 'this_month',
        dateFrom: null,
        dateTo: null,
      ),
    ).thenAnswer((_) async {
      kpisCallCount++;
      return _kpis;
    });
    when(
      () => mockRepository.fetchTodaysOverview(),
    ).thenAnswer((_) async => _overview);
    when(
      () => mockRepository.fetchRecentCases(),
    ).thenAnswer((_) async => <RecentCase>[]);

    await container.read(businessHealthProvider.future);
    await container.read(dashboardKpisProvider.future);
    expect(healthCallCount, 1);
    expect(kpisCallCount, 1);

    container.invalidate(businessHealthProvider);
    container.invalidate(dashboardKpisProvider);
    container.invalidate(todaysOverviewProvider);
    container.invalidate(recentCasesProvider);
    await Future.wait([
      container.read(businessHealthProvider.future),
      container.read(dashboardKpisProvider.future),
      container.read(todaysOverviewProvider.future),
      container.read(recentCasesProvider.future),
    ]);

    expect(healthCallCount, 2);
    expect(kpisCallCount, 2);
  });

  test(
    'dashboardKpisProvider watches kpiPeriodProvider — changing it refetches with the new period',
    () async {
      const lastWeekKpis = DashboardKpis(
        totalOutstandingAmount: '800.00',
        totalCollectedPeriod: '50.00',
        highRiskCustomers: 2,
        overdueCount: 2,
        overdueValue: '400.00',
        customersOverCreditLimit: 1,
        activeCollectionCases: 3,
      );
      when(
        () => mockRepository.fetchKpis(
          period: 'this_month',
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer((_) async => _kpis);
      when(
        () => mockRepository.fetchKpis(
          period: 'last_week',
          dateFrom: null,
          dateTo: null,
        ),
      ).thenAnswer((_) async => lastWeekKpis);

      final initial = await container.read(dashboardKpisProvider.future);
      expect(initial, _kpis);

      container.read(kpiPeriodProvider.notifier).state =
          const KpiPeriodSelection(key: 'last_week', label: 'Last Week');
      final afterChange = await container.read(dashboardKpisProvider.future);

      expect(afterChange, lastWeekKpis);
      verify(
        () => mockRepository.fetchKpis(
          period: 'last_week',
          dateFrom: null,
          dateTo: null,
        ),
      ).called(1);
    },
  );

  test(
    'dashboardKpisProvider forwards a custom range\'s date_from/date_to',
    () async {
      when(
        () => mockRepository.fetchKpis(
          period: 'custom',
          dateFrom: '2026-01-01',
          dateTo: '2026-01-31',
        ),
      ).thenAnswer((_) async => _kpis);

      container
          .read(kpiPeriodProvider.notifier)
          .state = const KpiPeriodSelection(
        key: 'custom',
        label: '2026-01-01 – 2026-01-31',
        dateFrom: '2026-01-01',
        dateTo: '2026-01-31',
      );
      final result = await container.read(dashboardKpisProvider.future);

      expect(result, _kpis);
    },
  );
}
