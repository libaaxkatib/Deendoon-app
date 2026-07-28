import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/dashboard_providers.dart';
import 'risk_badge.dart';

/// §4.5 Recent Cases — header with "View All", a short list of case
/// entries (customer name, outstanding amount, risk badge), most-recent-
/// activity first (already ordered server-side). Cases and Case Details
/// are out of scope this sprint, so both "View All" and individual case
/// taps surface "coming soon" instead of navigating.
class RecentCasesSection extends ConsumerWidget {
  const RecentCasesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cases = ref.watch(recentCasesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Recent Cases',
          trailing: TextButton(
            onPressed: () => showComingSoon(context, 'Cases'),
            child: const Text('View All'),
          ),
        ),
        cases.when(
          loading: () => const SectionLoading(),
          error: (error, _) => RetrySection(
            message: 'Could not load recent cases.',
            onRetry: () => ref.invalidate(recentCasesProvider),
          ),
          data: (data) {
            if (data.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No recent activity', style: AppTypography.body),
              );
            }
            return Column(
              children: [
                for (final recentCase in data)
                  ListTile(
                    onTap: () => showComingSoon(context, 'Case Details'),
                    title: Text(recentCase.customerName),
                    subtitle: Text(recentCase.outstandingAmount),
                    trailing: RiskBadge(riskLevel: recentCase.riskLevel),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
