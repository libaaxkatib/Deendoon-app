import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/debt_detail_providers.dart';

const _documentTypeLabels = {
  'receipt': 'Receipt',
  'demand_letter': 'Demand Letter',
  'statement': 'Statement',
  'invoice': 'Invoice',
};

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
    final documentsAsync = ref.watch(debtDocumentsProvider(debtId));

    return documentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => RetrySection(
        message: 'Could not load related documents.',
        onRetry: () => ref.invalidate(debtDocumentsProvider(debtId)),
      ),
      data: (documents) {
        if (documents.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No documents yet', style: AppTypography.body),
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
                        Text(document.referenceNumber, style: AppTypography.body),
                        const SizedBox(height: 2),
                        Text(
                          _documentTypeLabels[document.documentType] ?? document.documentType,
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
