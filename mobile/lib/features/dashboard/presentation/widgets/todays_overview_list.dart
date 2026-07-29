import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/widgets/app_card.dart';

/// §4.3 Today's Overview — four rows: Reminders Due Today, Payments Due,
/// Client Visits, Follow-up Calls. All four now open the real Reminder
/// Center (Sprint 14). They all land on the same "Today" tab rather than
/// a per-type filtered view — `GET /reminders` has no `reminder_type`
/// query parameter (confirmed by reading `ReminderCenterController`
/// in full), so a type-specific deep link isn't possible; the Reminder
/// List's own type icons let the user distinguish rows visually once
/// there.
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
            onTap: () => context.go('/reminders'),
          ),
          const SizedBox(height: 10),
          _OverviewRow(
            icon: Icons.payments_outlined,
            iconColor: AppColors.success,
            label: 'Payments Due',
            count: data.paymentsDue,
            onTap: () => context.go('/reminders'),
          ),
          const SizedBox(height: 10),
          _OverviewRow(
            icon: Icons.person_outline,
            iconColor: AppColors.accent,
            label: 'Client Visits',
            count: data.clientVisits,
            onTap: () => context.go('/reminders'),
          ),
          const SizedBox(height: 10),
          _OverviewRow(
            icon: Icons.call_outlined,
            iconColor: AppColors.warning,
            label: 'Follow-up Calls',
            count: data.followUpCalls,
            onTap: () => context.go('/reminders'),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppTypography.body)),
          Text('$count', style: AppTypography.subheading),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
