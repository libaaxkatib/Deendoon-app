import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/document_detail_providers.dart';

const _eventTypeLabels = <String, String>{
  'generated': 'Generated',
  'downloaded': 'Downloaded',
  'regenerated': 'Regenerated',
};

/// Document History (P2.5) — `GET /documents/{id}/history`
/// (`DocumentEventResource`): actor, action, and timestamp for every real,
/// backend-recorded event against this document. `user_id` is shown as a
/// raw id — there is no endpoint reachable by non-admin roles to resolve a
/// user id to a name (same gap as Reminder's "Created By" and Collection
/// Case's "Assigned Officer").
class DocumentHistoryScreen extends ConsumerWidget {
  final String documentId;

  const DocumentHistoryScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(documentHistoryProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Document History')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(documentHistoryProvider(documentId));
          await ref.read(documentHistoryProvider(documentId).future);
        },
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: 'Could not load this document\'s history.',
                onRetry: () => ref.invalidate(documentHistoryProvider(documentId)),
              ),
            ),
          ),
          data: (events) {
            if (events.isEmpty) {
              return const Center(child: Text('No history yet', style: AppTypography.body));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_eventTypeLabels[event.eventType] ?? event.eventType, style: AppTypography.body),
                            const SizedBox(height: 4),
                            Text(
                              event.userId != null ? 'User ${event.userId}' : 'System',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(formatFriendlyDateTimeFromIso(event.occurredAt), style: AppTypography.caption),
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
