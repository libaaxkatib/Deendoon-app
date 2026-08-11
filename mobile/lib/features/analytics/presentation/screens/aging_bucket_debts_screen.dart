import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../debts/presentation/widgets/debt_card.dart';
import '../../domain/aging_analysis.dart';
import '../providers/aging_analysis_provider.dart';

/// §5.5 "Tapping a legend row navigates to a Debts report filtered to
/// that aging bracket" — per explicit product decision, this reuses the
/// debts `agingAnalysisProvider` already fetched for the Overview chart
/// and filters them client-side by the real `aging_bucket` field. It
/// never issues its own request: if reached directly (no prior Overview
/// visit), it simply triggers that same provider's own first fetch —
/// still exactly one request, not a second one layered on top.
class AgingBucketDebtsScreen extends ConsumerWidget {
  final String bucket;

  const AgingBucketDebtsScreen({super.key, required this.bucket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final agingAsync = ref.watch(agingAnalysisProvider);

    return Scaffold(
      appBar: AppBar(title: Text(agingBucketLabels(l10n)[bucket] ?? l10n.debtListTitle)),
      body: agingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: RetrySection(
            message: l10n.debtListLoadError,
            onRetry: () => ref.invalidate(agingAnalysisProvider),
          ),
        ),
        data: (aging) {
          final matching = aging.debts.where((d) => d.agingBucket == bucket).toList();
          final bucketTotalCount = aging.buckets[bucket]?.count ?? matching.length;

          if (matching.isEmpty) {
            return Center(child: Text(l10n.agingBucketDebtsEmptyState, style: AppTypography.body));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (matching.length < bucketTotalCount)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.agingBucketDebtsShowingCountLabel(matching.length, bucketTotalCount),
                    style: AppTypography.caption,
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matching.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final debt = matching[index].debt;
                    return DebtCard(debt: debt, riskLevel: null, onTap: () => context.push('/debts/${debt.id}'));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
