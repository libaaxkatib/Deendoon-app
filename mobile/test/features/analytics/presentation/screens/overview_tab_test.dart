import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/aging_analysis.dart';
import 'package:mobile/features/analytics/domain/collection_analytics.dart';
import 'package:mobile/features/analytics/domain/collections_trend.dart';
import 'package:mobile/features/analytics/domain/risk_distribution.dart';
import 'package:mobile/features/analytics/presentation/screens/overview_tab.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

const _analytics = CollectionAnalytics(collectionRate: 40.0, totalCollected: '400.00', averageDays: 10.0);

const _aging = AgingAnalysis(
  buckets: {
    'current': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
    '1_30': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
    '31_60': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
    '61_90': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
    'over_90': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
  },
  debts: [],
  currentPage: 1,
  lastPage: 1,
  total: 0,
);

const _riskDistribution = RiskDistribution(segments: [
  RiskSegment(riskLevel: 'high', customerCount: 0, percentage: 0.0),
  RiskSegment(riskLevel: 'medium', customerCount: 0, percentage: 0.0),
  RiskSegment(riskLevel: 'low', customerCount: 0, percentage: 0.0),
]);

const _trend = CollectionsTrend(metric: 'collected_amount', series: [TrendPoint(date: '2026-07-28', value: '0.00')]);

Future<void> _pumpScreen(WidgetTester tester, {required _MockAnalyticsRepository repository}) async {
  tester.view.physicalSize = const Size(400, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  when(() => repository.fetchCollectionAnalytics(dateFrom: any(named: 'dateFrom'), dateTo: any(named: 'dateTo')))
      .thenAnswer((_) async => _analytics);
  when(() => repository.fetchAgingAnalysis()).thenAnswer((_) async => _aging);
  when(() => repository.fetchRiskDistribution()).thenAnswer((_) async => _riskDistribution);
  when(() => repository.fetchCollectionsTrend(dateFrom: any(named: 'dateFrom'), dateTo: any(named: 'dateTo')))
      .thenAnswer((_) async => _trend);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: Scaffold(body: OverviewTab())),
    ),
  );
}

void main() {
  late _MockAnalyticsRepository mockRepository;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
  });

  testWidgets('renders Collection Analytics with no delta, Aging Analysis, and Risk Distribution', (tester) async {
    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    expect(find.text('40.0%'), findsOneWidget);
    expect(find.text('400.00'), findsOneWidget);
    expect(find.text('10.0'), findsOneWidget);
    expect(find.textContaining('vs'), findsNothing);
    expect(find.text('Aging Analysis'), findsOneWidget);
    expect(find.text('Risk Distribution'), findsOneWidget);
  });

  testWidgets('tapping Collection Rate shows the "not available yet" message, not fake navigation', (tester) async {
    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Collection Rate'));
    await tester.pumpAndSettle();

    expect(find.text('Detailed view is not available yet.'), findsOneWidget);
  });

  testWidgets('tapping Average Days shows the "not available yet" message', (tester) async {
    await _pumpScreen(tester, repository: mockRepository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Average Days'));
    await tester.pumpAndSettle();

    expect(find.text('Detailed view is not available yet.'), findsOneWidget);
  });
}
