import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Overview tab's shared date range (§5.1 — drives Collection
/// Analytics and the compact Collections Trend chart; Aging Analysis is
/// deliberately NOT scoped to this range, see `aging_analysis_provider.dart`).
/// Defaults to the current calendar month, matching
/// `ReportingService::collectionAnalytics()`'s own default so the first
/// render already reflects what the backend would return with no params.
final overviewDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
});

/// The Trends tab's own, independently-selectable, extended range (§5.3:
/// "a selectable range longer than the default Overview period"). Defaults
/// to the trailing 30 days.
final trendsDateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: now.subtract(const Duration(days: 29)), end: now);
});
