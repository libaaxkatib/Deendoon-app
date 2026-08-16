import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics_repository.dart';
import '../../domain/collection_analytics.dart';
import 'date_range_providers.dart';

String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

/// §5.4 — recomputes whenever `overviewDateRangeProvider` changes, per the
/// Overview tab's business rule ("all figures recompute immediately
/// whenever the date range changes"). No "vs previous period" delta is
/// requested or displayed — the backend does not provide one.
final collectionAnalyticsProvider = FutureProvider<CollectionAnalytics>((ref) {
  final range = ref.watch(overviewDateRangeProvider);
  return ref
      .read(analyticsRepositoryProvider)
      .fetchCollectionAnalytics(
        dateFrom: _isoDate(range.start),
        dateTo: _isoDate(range.end),
      );
});
