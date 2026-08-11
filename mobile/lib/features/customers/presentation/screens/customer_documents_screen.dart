import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/customer_detail_providers.dart';

Map<String, String> _documentTypeLabels(AppLocalizations l10n) => {
      'receipt': l10n.documentTypeReceipt,
      'demand_letter': l10n.documentTypeDemandLetter,
      'statement': l10n.documentTypeStatement,
      'invoice': l10n.documentTypeInvoice,
    };

/// Customer Detail's "Documents" destination — `GET /customers/{id}/documents`
/// (`DocumentController::forCustomer`), combining Receipts, Demand Letters,
/// Statements, and Invoices exactly as the backend already does (same real
/// endpoint `DebtDocumentsSection` uses for its per-debt equivalent, just
/// scoped to the customer instead). Flat, unpaginated list — the backend
/// returns every related document in one response, no infinite scroll.
class CustomerDocumentsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDocumentsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final documentsAsync = ref.watch(customerDocumentsProvider(customerId));
    final documentTypeLabels = _documentTypeLabels(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navDocuments)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerDocumentsProvider(customerId));
          await ref.read(customerDocumentsProvider(customerId).future);
        },
        child: documentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: RetrySection(
              message: l10n.customerDocumentsLoadError,
              onRetry: () => ref.invalidate(customerDocumentsProvider(customerId)),
            ),
          ),
          data: (documents) {
            if (documents.isEmpty) {
              return Center(child: Text(l10n.customerDocumentsEmptyState, style: AppTypography.body));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final document = documents[index];
                return AppCard(
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
                            documentTypeLabels[document.documentType] ?? document.documentType,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                      Text(document.generatedAt, style: AppTypography.caption),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
