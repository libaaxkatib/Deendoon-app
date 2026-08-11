import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/risk_badge.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar_initial.dart';

/// §4.5 Recent Cases — header with "View All", a short list of case
/// entries (customer name, outstanding amount, risk badge), most-recent-
/// activity first (already ordered server-side). "View All" switches to
/// the real Cases tab; each row opens the real Case Detail screen
/// (`RecentCase.id` already matches `CollectionCase.id`).
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
            onPressed: () => context.go(RoutePaths.cases),
            child: const Text('View All'),
          ),
        ),
        const SizedBox(height: 8),
        cases.when(
          loading: () => const SectionLoading(),
          error: (error, _) => RetrySection(
            message: 'Could not load recent cases.',
            onRetry: () => ref.invalidate(recentCasesProvider),
          ),
          data: (data) {
            if (data.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No recent activity',
                  style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                ),
              );
            }
            return Column(
              children: [
                for (final recentCase in data) ...[
                  AppCard(
                    onTap: () => context.push('/cases/${recentCase.id}'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        AvatarInitial(name: recentCase.customerName, radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recentCase.customerName,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                recentCase.outstandingAmount,
                                style: AppTypography.caption.copyWith(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        RiskBadge(riskLevel: recentCase.riskLevel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
