import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/widgets/app_card.dart';

/// §4.3 Today's Overview — four rows: Reminders Due Today, Payments Due,
/// Client Visits, Follow-ups (Deendoon V1 Reminder Workflow Update:
/// renamed from "Follow-up Calls" — label only, same
/// `data.followUpCalls` count and same `?filter=calls` route). All four
/// open the real Reminder
/// Center (Sprint 14) with the matching filter chip already selected via
/// the `?filter=` query param (`ReminderListScreen.initialFilter`) — a
/// client-side deep link only, since `GET /reminders` itself still has
/// no `reminder_type` query parameter (confirmed by reading
/// `ReminderCenterController` in full); the Reminder Center filters its
/// own already-fetched "All" page by the real `Reminder.type` field
/// rather than asking the backend for anything new.
class TodaysOverviewList extends ConsumerWidget {
  const TodaysOverviewList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(todaysOverviewProvider);

    return overview.when(
      loading: () => const SectionLoading(),
      error: (error, _) => RetrySection(
        message: "Could not load today's overview.",
        onRetry: () => ref.invalidate(todaysOverviewProvider),
      ),
      data: (data) => Column(
        children: [
          _OverviewRow(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.info,
            label: 'Reminders Due Today',
            count: data.totalDueToday,
            onTap: () => context.go('/reminders?filter=today'),
          ),
          const SizedBox(height: 2),
          _OverviewRow(
            icon: Icons.payments_outlined,
            iconColor: AppColors.success,
            label: 'Payments Due',
            count: data.paymentsDue,
            onTap: () => context.go('/reminders?filter=payments'),
          ),
          const SizedBox(height: 2),
          _OverviewRow(
            icon: Icons.person_outline,
            iconColor: AppColors.accent,
            label: 'Client Visits',
            count: data.clientVisits,
            onTap: () => context.go('/reminders?filter=visits'),
          ),
          const SizedBox(height: 2),
          _OverviewRow(
            icon: Icons.call_outlined,
            iconColor: AppColors.warning,
            label: 'Follow-ups',
            count: data.followUpCalls,
            onTap: () => context.go('/reminders?filter=calls'),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _OverviewRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
      splashColor: iconColor.withValues(alpha: 0.14),
      highlightColor: iconColor.withValues(alpha: 0.06),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.body.copyWith(color: context.colors.textPrimary))),
          Text(
            '$count',
            style: AppTypography.subheading.copyWith(fontWeight: FontWeight.w800, color: context.colors.textPrimary),
          ),
          const SizedBox(width: 6),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.colors.textSecondary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right, size: 16, color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
