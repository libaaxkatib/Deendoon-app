import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../domain/calendar_entry.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_agenda_tile.dart';
import '../widgets/calendar_month_grid.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String _monthLabel(DateTime month) => '${_monthNames[month.month - 1]} ${month.year}';

String _selectedDayLabel(DateTime date) =>
    '${_weekdayNames[date.weekday - 1]}, ${_monthNames[date.month - 1]} ${date.day}';

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Smart Calendar — `Mobile_UI_V1_Frozen.md` §7.6. Read-only aggregation
/// over `GET /calendar` (`CalendarController::index`): Debt due dates,
/// open Promise to Pay dates, manual follow-up history, and open
/// Reminders. Collection Appointments are not included — the backend
/// itself does not aggregate them (no date field on `collection_cases`,
/// see the controller's own docblock).
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(visibleMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dataAsync = ref.watch(calendarMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                  onPressed: () => ref.read(visibleMonthProvider.notifier).state =
                      DateTime(month.year, month.month - 1),
                ),
                Text(_monthLabel(month), style: AppTypography.subheading),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                  onPressed: () => ref.read(visibleMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: RetrySection(
                  message: 'Could not load calendar data.',
                  onRetry: () => ref.invalidate(calendarMonthProvider),
                ),
              ),
              data: (data) {
                final entriesByDate = <String, List<CalendarEntry>>{};
                for (final entry in data.entries) {
                  entriesByDate.putIfAbsent(entry.date, () => []).add(entry);
                }
                final dayEntries = entriesByDate[_dateKey(selectedDate)] ?? const <CalendarEntry>[];

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    CalendarMonthGrid(
                      month: month,
                      selectedDate: selectedDate,
                      datesWithEntries: entriesByDate.keys.toSet(),
                      onDaySelected: (date) => ref.read(selectedDateProvider.notifier).state = date,
                    ),
                    const SizedBox(height: 16),
                    Text(_selectedDayLabel(selectedDate), style: AppTypography.subheading),
                    const SizedBox(height: 12),
                    if (dayEntries.isEmpty)
                      const PremiumEmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'No events',
                        message: 'Nothing due, promised, or scheduled on this day.',
                      )
                    else
                      for (final entry in dayEntries) ...[
                        CalendarAgendaTile(entry: entry),
                        if (entry != dayEntries.last) const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
