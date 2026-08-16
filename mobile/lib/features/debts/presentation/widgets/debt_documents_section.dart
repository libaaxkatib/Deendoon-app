import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/debt_detail_providers.dart';

/// Related Documents — `GET /debts/{id}/documents`
/// (`DocumentController::forDebt`), combining Receipts, Demand Letters,
/// Statements, and Invoices exactly as the backend already does. Tapping
/// an entry opens the real Document Preview screen (Sprint 15) —
/// `GET /documents/{id}` resolves any document id across all four
/// underlying tables regardless of which endpoint originally listed it,
/// so this reuses the exact same screen the Documents Center itself
/// navigates to.
class DebtDocumentsSection extends ConsumerWidget {
  final String debtId;

  const DebtDocumentsSection({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final documentsAsync = ref.watch(debtDocumentsProvider(debtId));
    final documentTypeLabels = <String, String>{
      'receipt': l10n.documentTypeReceipt,
      'demand_letter': l10n.documentTypeDemandLetter,
      'statement': l10n.documentTypeStatement,
      'invoice': l10n.documentTypeInvoice,
    };

    return documentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: l10n.debtDocumentsLoadError,
        onRetry: () => ref.invalidate(debtDocumentsProvider(debtId)),
      ),
      data: (documents) {
        if (documents.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.customerDocumentsEmptyState,
              style: AppTypography.body,
            ),
          );
        }

        return Column(
          children: [
            for (final document in documents) ...[
              AppCard(
                onTap: () => context.push('/documents/${document.id}'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.referenceNumber,
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          documentTypeLabels[document.documentType] ??
                              document.documentType,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                    Text(document.generatedAt, style: AppTypography.caption),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}
