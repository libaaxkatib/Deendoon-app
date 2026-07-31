import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/analytics/data/analytics_repository.dart';
import 'package:mobile/features/analytics/domain/collection_analytics.dart';
import 'package:mobile/features/analytics/presentation/providers/collection_analytics_provider.dart';
import 'package:mobile/features/analytics/presentation/providers/date_range_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = _MockAnalyticsRepository();
    container = ProviderContainer(
      overrides: [analyticsRepositoryProvider.overrideWithValue(mockRepository)],
    );
    addTearDown(container.dispose);
  });

  test('fetches under the current overviewDateRangeProvider range', () async {
    final range = container.read(overviewDateRangeProvider);
    final dateFrom = range.start.toIso8601String().split('T').first;
    final dateTo = range.end.toIso8601String().split('T').first;
    const analytics = CollectionAnalytics(collectionRate: 40.0, totalCollected: '400.00', averageDays: 10.0);
    when(() => mockRepository.fetchCollectionAnalytics(dateFrom: dateFrom, dateTo: dateTo))
        .thenAnswer((_) async => analytics);

    final result = await container.read(collectionAnalyticsProvider.future);

    expect(result, analytics);
  });

  test('recomputes when overviewDateRangeProvider changes', () async {
    final initialRange = container.read(overviewDateRangeProvider);
    when(() => mockRepository.fetchCollectionAnalytics(
          dateFrom: initialRange.start.toIso8601String().split('T').first,
          dateTo: initialRange.end.toIso8601String().split('T').first,
        )).thenAnswer((_) async => const CollectionAnalytics(collectionRate: 10.0, totalCollected: '100.00', averageDays: null));
    await container.read(collectionAnalyticsProvider.future);

    final newRange = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
    when(() => mockRepository.fetchCollectionAnalytics(dateFrom: '2026-01-01', dateTo: '2026-01-31'))
        .thenAnswer((_) async => const CollectionAnalytics(collectionRate: 90.0, totalCollected: '900.00', averageDays: 5.0));

    container.read(overviewDateRangeProvider.notifier).state = newRange;
    final result = await container.read(collectionAnalyticsProvider.future);

    expect(result.collectionRate, 90.0);
  });
}
