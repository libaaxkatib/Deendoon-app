import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/aging_analysis.dart';
import 'package:mobile/features/analytics/presentation/screens/aging_bucket_debts_screen.dart';
import 'package:mobile/features/debts/domain/debt.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

const _currentDebt = Debt(
  id: '1',
  customerId: '1',
  referenceNumber: 'DBT-000001',
  amount: '500.00',
  dueDate: '2026-08-01',
  debtStatus: 'pending',
  remainingBalance: '500.00',
  recoveryStage: 1,
  notes: null,
);

const _overdueDebt = Debt(
  id: '2',
  customerId: '2',
  referenceNumber: 'DBT-000002',
  amount: '300.00',
  dueDate: '2026-06-01',
  debtStatus: 'overdue',
  remainingBalance: '300.00',
  recoveryStage: 2,
  notes: null,
);

const _aging = AgingAnalysis(
  buckets: {
    'current': AgingBucket(count: 1, totalRemainingBalance: '500.00'),
    '1_30': AgingBucket(count: 1, totalRemainingBalance: '300.00'),
    '31_60': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
    '61_90': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
    'over_90': AgingBucket(count: 0, totalRemainingBalance: '0.00'),
  },
  debts: [
    AgingDebt(debt: _currentDebt, agingBucket: 'current'),
    AgingDebt(debt: _overdueDebt, agingBucket: '1_30'),
  ],
  currentPage: 1,
  lastPage: 1,
  total: 2,
);

Future<void> _pumpScreen(WidgetTester tester, {required _MockAnalyticsRepository repository, required String bucket}) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: AgingBucketDebtsScreen(bucket: bucket)),
    ),
  );
}

void main() {
  late _MockAnalyticsRepository mockRepository;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
    when(() => mockRepository.fetchAgingAnalysis()).thenAnswer((_) async => _aging);
  });

  testWidgets('shows only the debts matching the tapped bucket, filtered client-side', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, bucket: '1_30');
    await tester.pumpAndSettle();

    expect(find.text('DBT-000002'), findsOneWidget);
    expect(find.text('DBT-000001'), findsNothing);
  });

  testWidgets('issues exactly one request regardless of which bucket is opened', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, bucket: 'current');
    await tester.pumpAndSettle();

    verify(() => mockRepository.fetchAgingAnalysis()).called(1);
  });

  testWidgets('shows the explicit empty state for a bucket with no debts', (tester) async {
    await _pumpScreen(tester, repository: mockRepository, bucket: '31_60');
    await tester.pumpAndSettle();

    expect(find.text('No debts in this bucket'), findsOneWidget);
  });

  testWidgets('shows a retry affordance when aging analysis fails to load', (tester) async {
    final failingRepository = _MockAnalyticsRepository();
    when(() => failingRepository.fetchAgingAnalysis()).thenThrow(Exception('network down'));

    await _pumpScreen(tester, repository: failingRepository, bucket: 'current');
    await tester.pumpAndSettle();

    expect(find.text('Could not load debts.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
