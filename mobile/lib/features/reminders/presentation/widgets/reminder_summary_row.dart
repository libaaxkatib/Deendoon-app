import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/reminder_detail_providers.dart';

/// §7.1 Dashboard — "a total due-today count plus per-type sub-counts
/// (Visits, Calls, Payments) and an Overdue count." Loads and errors
/// independently of the list below it, per the section's own "each
/// component loads independently" rule.
class ReminderSummaryRow extends ConsumerWidget {
  const ReminderSummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(reminderSummaryProvider);

    return summaryAsync.when(
      loading: () => const SectionLoading(),
      error: (error, _) => RetrySection(
        message: 'Could not load the summary.',
        onRetry: () => ref.invalidate(reminderSummaryProvider),
      ),
      data: (summary) => Column(
        children: [
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Due Today', style: AppTypography.caption),
                Text(
                  '${summary.totalDueToday}',
                  style: AppTypography.subheading.copyWith(color: AppColors.primary, fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Visits', value: summary.clientVisits)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Calls', value: summary.followUpCalls)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Payments', value: summary.paymentsDue)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Overdue', value: summary.overdueCount, color: AppColors.danger)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color? color;

  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          Text('$value', style: AppTypography.subheading.copyWith(color: color ?? AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
