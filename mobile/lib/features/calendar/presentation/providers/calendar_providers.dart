import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/calendar_repository.dart';
import '../../domain/calendar_data.dart';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The month currently shown in the grid, normalized to its first day.
/// Defaults to the real current month.
final visibleMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// The selected day in the grid — defaults to today.
final selectedDateProvider = StateProvider<DateTime>(
  (ref) => _startOfDay(DateTime.now()),
);

/// Fetches `GET /calendar` for the visible month's real date range
/// (first day through last day) — re-fetches automatically whenever
/// `visibleMonthProvider` changes, since Previous/Next month navigation
/// always means new backend data, not a client-side filter over
/// already-fetched entries.
final calendarMonthProvider = FutureProvider<CalendarData>((ref) {
  final month = ref.watch(visibleMonthProvider);
  final from = DateTime(month.year, month.month, 1);
  final to = DateTime(month.year, month.month + 1, 0);
  return ref
      .watch(calendarRepositoryProvider)
      .fetchEntries(from: _isoDate(from), to: _isoDate(to));
});
