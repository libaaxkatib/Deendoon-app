import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

List<String> _weekdayLabels(AppLocalizations l10n) => [
  l10n.weekdayMon,
  l10n.weekdayTue,
  l10n.weekdayWed,
  l10n.weekdayThu,
  l10n.weekdayFri,
  l10n.weekdaySat,
  l10n.weekdaySun,
];

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Month grid — Monday-first, current day highlighted, selected day filled,
/// a dot under any date carrying at least one real backend entry. Matches
/// `Mobile_UI_V1_Frozen.md` §7.6's "calendar grid with the current day
/// highlighted and dates carrying items visually marked."
class CalendarMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final Set<String> datesWithEntries;
  final ValueChanged<DateTime> onDaySelected;

  const CalendarMonthGrid({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.datesWithEntries,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateTime.now();
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels(l10n))
              Expanded(
                child: Center(
                  child: Text(label, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();

            final day = index - leadingBlanks + 1;
            final date = DateTime(month.year, month.month, day);
            final isToday = _isSameDay(date, today);
            final isSelected = _isSameDay(date, selectedDate);
            final dateKey =
                '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final hasEntries = datesWithEntries.contains(dateKey);

            return _DayCell(
              day: day,
              isToday: isToday,
              isSelected: isSelected,
              hasEntries: hasEntries,
              onTap: () => onDaySelected(date),
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isSelected;
  final bool hasEntries;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasEntries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color? background = isSelected ? AppColors.primary : (isToday ? AppColors.primary.withValues(alpha: 0.15) : null);
    final Color textColor = isSelected ? context.colors.background : context.colors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Text('$day', style: AppTypography.body.copyWith(color: textColor)),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 6,
              width: 6,
              child: hasEntries
                  ? DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
