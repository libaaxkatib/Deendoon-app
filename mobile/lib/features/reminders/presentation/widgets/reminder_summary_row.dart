import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/reminder_detail_providers.dart';
import '../providers/reminder_list_provider.dart';

/// §7.1 Dashboard — "a total due-today count plus per-type sub-counts
/// (Visits, Calls, Payments) and an Overdue count." Loads and errors
/// independently of the list below it, per the section's own "each
/// component loads independently" rule. Each mini-stat is also a
/// shortcut into the matching filter chip below (Client Visits/Follow-ups/
/// Payments are client-side `Reminder.type` filters, Overdue is the real
/// backend `tab=overdue`) rather than a second, separate navigation
/// target. Labels renamed (Deendoon V1 Reminder Workflow Update) to match
/// the filter chips below — same underlying `client_visit`/`follow_up_call`
/// type filters, label-only change.
class ReminderSummaryRow extends ConsumerWidget {
  const ReminderSummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(reminderSummaryProvider);

    return summaryAsync.when(
      loading: () => const SectionLoading(),
      error: (error, _) => RetrySection(
        message: l10n.reminderSummaryLoadError,
        onRetry: () => ref.invalidate(reminderSummaryProvider),
      ),
      data: (summary) => Column(
        children: [
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.reminderSummaryDueTodayLabel,
                  style: AppTypography.caption,
                ),
                Text(
                  '${summary.totalDueToday}',
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l10n.todaysOverviewClientVisits,
                  value: summary.clientVisits,
                  onTap: () => ref
                      .read(reminderListProvider.notifier)
                      .filterByType('client_visit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: l10n.todaysOverviewFollowUps,
                  value: summary.followUpCalls,
                  onTap: () => ref
                      .read(reminderListProvider.notifier)
                      .filterByType('follow_up_call'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: l10n.reminderFilterPayments,
                  value: summary.paymentsDue,
                  onTap: () => ref
                      .read(reminderListProvider.notifier)
                      .filterByType('payment_due'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: l10n.statusOverdue,
                  value: summary.overdueCount,
                  color: AppColors.danger,
                  onTap: () => ref
                      .read(reminderListProvider.notifier)
                      .filterByTab('overdue'),
                ),
              ),
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
  final VoidCallback onTap;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.subheading.copyWith(
              color: color ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
