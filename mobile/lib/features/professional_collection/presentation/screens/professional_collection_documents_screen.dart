import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/professional_collection_detail_providers.dart';

const _documentTypeLabels = {
  'receipt': 'Receipt',
  'demand_letter': 'Demand Letter',
  'statement': 'Statement',
  'invoice': 'Invoice',
};

/// Professional Collection Request's "Documents" destination —
/// `GET /professional-requests/{id}/documents` — the existing Receipt/
/// Demand Letter/Statement/Invoice rows auto-linked at submission, same
/// visual pattern as `CustomerDocumentsScreen`. Read-only, available to
/// the Business Owner throughout the Request's entire lifecycle
/// (`viewDocuments` policy — unaffected by upload-permission staging).
class ProfessionalCollectionDocumentsScreen extends ConsumerWidget {
  final String requestId;

  const ProfessionalCollectionDocumentsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(professionalCollectionDocumentsProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(professionalCollectionDocumentsProvider(requestId));
          await ref.read(professionalCollectionDocumentsProvider(requestId).future);
        },
        child: documentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: RetrySection(
              message: 'Could not load documents.',
              onRetry: () => ref.invalidate(professionalCollectionDocumentsProvider(requestId)),
            ),
          ),
          data: (documents) {
            if (documents.isEmpty) {
              return const Center(child: Text('No documents linked to this Request yet', style: AppTypography.body));
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
                            _documentTypeLabels[document.documentType] ?? document.documentType,
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
