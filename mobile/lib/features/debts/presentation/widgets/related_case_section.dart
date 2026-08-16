import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../cases/presentation/widgets/case_card.dart';
import '../providers/debt_detail_providers.dart';

/// Related Case (mobile Item 12) — `GET /debts/{id}/collection-case`
/// (`CollectionCaseController::forDebt`). Null is a real, expected value
/// (no case has been opened for this debt yet), not an error.
class RelatedCaseSection extends ConsumerWidget {
  final String debtId;

  const RelatedCaseSection({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final caseAsync = ref.watch(debtRelatedCaseProvider(debtId));

    return caseAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.debtRelatedCaseLoadError,
        onRetry: () => ref.invalidate(debtRelatedCaseProvider(debtId)),
      ),
      data: (collectionCase) {
        if (collectionCase == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.debtRelatedCaseEmptyState,
              style: AppTypography.body,
            ),
          );
        }

        return CaseCard(
          collectionCase: collectionCase,
          activeTab: null,
          onTap: () => context.push('/cases/${collectionCase.id}'),
        );
      },
    );
  }
}
