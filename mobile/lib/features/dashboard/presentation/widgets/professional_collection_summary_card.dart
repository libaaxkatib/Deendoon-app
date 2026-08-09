import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../professional_collection/presentation/providers/professional_collection_summary_provider.dart';

/// Home Dashboard's Professional Collection summary — `GET
/// /professional-requests/summary`, the real aggregate the backend
/// computes (Total Active/Total Recovered counts across all 8 real
/// statuses, plus the single most-recently-created Request). The
/// endpoint does not return a multi-row list, only one aggregate plus
/// one "latest" record, so the card shows exactly that shape — a compact
/// stat row plus a single tappable "Latest Request" entry — rather than
/// inventing a multi-row table the backend doesn't provide.
class ProfessionalCollectionSummaryCard extends ConsumerWidget {
  const ProfessionalCollectionSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(professionalCollectionSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Professional Collection',
          trailing: TextButton(
            onPressed: () => context.push('/professional-requests'),
            child: const Text('View All'),
          ),
        ),
        const SizedBox(height: 8),
        summaryAsync.when(
          loading: () => const SectionLoading(),
          error: (error, _) => RetrySection(
            message: 'Could not load Professional Collection summary.',
            onRetry: () => ref.invalidate(professionalCollectionSummaryProvider),
          ),
          data: (summary) {
            if (summary.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No cases submitted to Deendoon yet', style: AppTypography.body),
              );
            }

            return AppCard(
              onTap: summary.latestRequest == null
                  ? null
                  : () => context.push('/professional-requests/${summary.latestRequest!.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatColumn(label: 'Active', value: summary.totalActive),
                      ),
                      Expanded(
                        child: _StatColumn(label: 'Recovered', value: summary.totalRecovered),
                      ),
                    ],
                  ),
                  if (summary.latestRequest != null) ...[
                    const Divider(height: 24, color: AppColors.background),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Latest Request', style: AppTypography.caption),
                              const SizedBox(height: 2),
                              Text(summary.latestRequest!.referenceNumber, style: AppTypography.body),
                            ],
                          ),
                        ),
                        StatusBadge(status: summary.latestRequest!.status),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: AppTypography.subheading.copyWith(color: AppColors.primary, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
