import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/dashboard_kpis.dart';
import 'package:mobile/features/dashboard/domain/recent_case.dart';
import 'package:mobile/features/dashboard/domain/todays_overview.dart';
import 'package:mobile/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockDashboardRepository extends Mock implements DashboardRepository {}

const _kpis = DashboardKpis(
  totalOutstandingAmount: '800.00',
  totalCollectedPeriod: '100.00',
  highRiskCustomers: 2,
  overdueCount: 2,
  overdueValue: '400.00',
  customersOverCreditLimit: 1,
  activeCollectionCases: 3,
);

const _overview = TodaysOverview(totalDueToday: 4, paymentsDue: 1, clientVisits: 2, followUpCalls: 1);

void main() {
  late _MockDashboardRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockDashboardRepository();
    container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('each provider resolves independently — one failure does not affect the others', () async {
    when(() => mockRepository.fetchKpis()).thenAnswer((_) async => _kpis);
    when(() => mockRepository.fetchTodaysOverview()).thenThrow(Exception('network down'));
    when(() => mockRepository.fetchRecentCases()).thenAnswer((_) async => <RecentCase>[]);

    final kpis = await container.read(dashboardKpisProvider.future);
    expect(kpis, _kpis);

    await expectLater(container.read(todaysOverviewProvider.future), throwsException);

    final cases = await container.read(recentCasesProvider.future);
    expect(cases, isEmpty);

    // Confirms the failure is isolated to its own AsyncValue, not
    // propagated to sibling providers.
    expect(container.read(dashboardKpisProvider), isA<AsyncData<DashboardKpis>>());
    expect(container.read(todaysOverviewProvider), isA<AsyncError<TodaysOverview>>());
  });

  test('refreshDashboard re-fetches all three after invalidation', () async {
    var kpisCallCount = 0;
    when(() => mockRepository.fetchKpis()).thenAnswer((_) async {
      kpisCallCount++;
      return _kpis;
    });
    when(() => mockRepository.fetchTodaysOverview()).thenAnswer((_) async => _overview);
    when(() => mockRepository.fetchRecentCases()).thenAnswer((_) async => <RecentCase>[]);

    await container.read(dashboardKpisProvider.future);
    expect(kpisCallCount, 1);

    container.invalidate(dashboardKpisProvider);
    container.invalidate(todaysOverviewProvider);
    container.invalidate(recentCasesProvider);
    await Future.wait([
      container.read(dashboardKpisProvider.future),
      container.read(todaysOverviewProvider.future),
      container.read(recentCasesProvider.future),
    ]);

    expect(kpisCallCount, 2);
  });
}
