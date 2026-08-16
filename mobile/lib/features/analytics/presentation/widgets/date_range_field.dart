import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/generated/app_localizations.dart';

List<String> _monthNames(AppLocalizations l10n) => [
  l10n.dateRangeMonthJan,
  l10n.dateRangeMonthFeb,
  l10n.dateRangeMonthMar,
  l10n.dateRangeMonthApr,
  l10n.dateRangeMonthMay,
  l10n.dateRangeMonthJun,
  l10n.dateRangeMonthJul,
  l10n.dateRangeMonthAug,
  l10n.dateRangeMonthSep,
  l10n.dateRangeMonthOct,
  l10n.dateRangeMonthNov,
  l10n.dateRangeMonthDec,
];

/// Sprint 16.1 polish: a friendlier "May 1 – May 31, 2026" display instead
/// of raw ISO dates — pure presentation formatting, no new date package,
/// no change to the underlying `DateTimeRange` value/filtering.
String _formatRange(DateTimeRange range, AppLocalizations l10n) {
  final start = range.start;
  final end = range.end;
  final monthNames = _monthNames(l10n);
  final startMonth = monthNames[start.month - 1];
  final endMonth = monthNames[end.month - 1];

  if (start.year == end.year && start.month == end.month) {
    return '$startMonth ${start.day} – ${end.day}, ${end.year}';
  }
  if (start.year == end.year) {
    return '$startMonth ${start.day} – $endMonth ${end.day}, ${end.year}';
  }
  return '$startMonth ${start.day}, ${start.year} – $endMonth ${end.day}, ${end.year}';
}

/// Shared date-range trigger for Overview (§5.1) and Trends (§5.3), and
/// reused by Reports > Payments' own date filter. Uses Flutter's built-in
/// `showDateRangePicker` — no date-picker package added.
class DateRangeField extends StatelessWidget {
  final DateTimeRange value;
  final ValueChanged<DateTimeRange> onChanged;

  const DateRangeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: value,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      onTap: () => _pick(context),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatRange(value, l10n),
              style: AppTypography.subheading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
