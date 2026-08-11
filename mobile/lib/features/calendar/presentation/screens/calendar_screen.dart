import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/premium_empty_state.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/calendar_entry.dart';
import '../providers/calendar_providers.dart';
import '../widgets/calendar_agenda_tile.dart';
import '../widgets/calendar_month_grid.dart';

List<String> _monthNames(AppLocalizations l10n) => [
  l10n.monthJan,
  l10n.monthFeb,
  l10n.monthMar,
  l10n.monthApr,
  l10n.monthMay,
  l10n.monthJun,
  l10n.monthJul,
  l10n.monthAug,
  l10n.monthSep,
  l10n.monthOct,
  l10n.monthNov,
  l10n.monthDec,
];

List<String> _weekdayNames(AppLocalizations l10n) => [
  l10n.calendarWeekdayMonday,
  l10n.calendarWeekdayTuesday,
  l10n.calendarWeekdayWednesday,
  l10n.calendarWeekdayThursday,
  l10n.calendarWeekdayFriday,
  l10n.calendarWeekdaySaturday,
  l10n.calendarWeekdaySunday,
];

String _monthLabel(AppLocalizations l10n, DateTime month) => '${_monthNames(l10n)[month.month - 1]} ${month.year}';

String _selectedDayLabel(AppLocalizations l10n, DateTime date) =>
    '${_weekdayNames(l10n)[date.weekday - 1]}, ${_monthNames(l10n)[date.month - 1]} ${date.day}';

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
    final l10n = AppLocalizations.of(context);
    final month = ref.watch(visibleMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dataAsync = ref.watch(calendarMonthProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.calendarTitle)),
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
                  tooltip: l10n.calendarPreviousMonthTooltip,
                  onPressed: () => ref.read(visibleMonthProvider.notifier).state =
                      DateTime(month.year, month.month - 1),
                ),
                Text(_monthLabel(l10n, month), style: AppTypography.subheading),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: l10n.calendarNextMonthTooltip,
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
                  message: l10n.calendarLoadError,
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
                    Text(_selectedDayLabel(l10n, selectedDate), style: AppTypography.subheading),
                    const SizedBox(height: 12),
                    if (dayEntries.isEmpty)
                      PremiumEmptyState(
                        icon: Icons.event_available_outlined,
                        title: l10n.calendarEmptyStateTitle,
                        message: l10n.calendarEmptyStateMessage,
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
