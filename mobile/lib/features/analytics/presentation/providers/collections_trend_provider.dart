import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics_repository.dart';
import '../../domain/collections_trend.dart';

String _isoDate(DateTime date) => date.toIso8601String().split('T').first;

/// §5.3 — keyed by the caller's own `DateTimeRange` so the Overview tab's
/// compact chart (driven by `overviewDateRangeProvider`) and the Trends
/// tab's full chart (driven by `trendsDateRangeProvider`) each fetch their
/// own independent range without fighting over one shared provider.
/// `collected_amount` is the only metric — see `collections_trend.dart`.
final collectionsTrendProvider =
    FutureProvider.family<CollectionsTrend, DateTimeRange>((ref, range) {
      return ref
          .read(analyticsRepositoryProvider)
          .fetchCollectionsTrend(
            dateFrom: _isoDate(range.start),
            dateTo: _isoDate(range.end),
          );
    });
