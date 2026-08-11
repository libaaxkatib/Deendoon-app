import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final summaryAsync = ref.watch(professionalCollectionSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.professionalCollectionTitle,
          trailing: TextButton(
            onPressed: () => context.push('/professional-requests'),
            child: Text(l10n.commonViewAll),
          ),
        ),
        const SizedBox(height: 8),
        summaryAsync.when(
          loading: () => const SectionLoading(),
          error: (error, _) => RetrySection(
            message: l10n.professionalCollectionLoadError,
            onRetry: () => ref.invalidate(professionalCollectionSummaryProvider),
          ),
          data: (summary) {
            if (summary.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.professionalCollectionEmptyState,
                  style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                ),
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
                        child: _StatColumn(label: l10n.statusActive, value: summary.totalActive),
                      ),
                      Expanded(
                        child: _StatColumn(label: l10n.statusRecovered, value: summary.totalRecovered),
                      ),
                    ],
                  ),
                  if (summary.latestRequest != null) ...[
                    Divider(height: 24, color: context.colors.background),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.professionalCollectionLatestRequestLabel,
                                style: AppTypography.caption.copyWith(color: context.colors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                summary.latestRequest!.referenceNumber,
                                style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                              ),
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
        Text(label, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
      ],
    );
  }
}
