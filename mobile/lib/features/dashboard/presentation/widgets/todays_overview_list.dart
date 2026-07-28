import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/dashboard_providers.dart';

/// §4.3 Today's Overview — four rows: Reminders Due Today, Payments Due,
/// Client Visits, Follow-up Calls. Each would open a filtered Reminder
/// Center list, out of scope this sprint, so rows surface "coming soon".
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
            label: 'Reminders Due Today',
            count: data.totalDueToday,
            onTap: () => showComingSoon(context, 'Reminder Center'),
          ),
          _OverviewRow(
            icon: Icons.payments_outlined,
            label: 'Payments Due',
            count: data.paymentsDue,
            onTap: () => showComingSoon(context, 'Reminder Center'),
          ),
          _OverviewRow(
            icon: Icons.person_outline,
            label: 'Client Visits',
            count: data.clientVisits,
            onTap: () => showComingSoon(context, 'Reminder Center'),
          ),
          _OverviewRow(
            icon: Icons.call_outlined,
            label: 'Follow-up Calls',
            count: data.followUpCalls,
            onTap: () => showComingSoon(context, 'Reminder Center'),
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count'),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}
