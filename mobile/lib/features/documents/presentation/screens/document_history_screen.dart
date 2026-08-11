import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/document_detail_providers.dart';

Map<String, String> _eventTypeLabels(AppLocalizations l10n) => {
      'generated': l10n.documentEventGenerated,
      'downloaded': l10n.documentEventDownloaded,
      'regenerated': l10n.documentEventRegenerated,
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
    final l10n = AppLocalizations.of(context);
    final historyAsync = ref.watch(documentHistoryProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.documentHistoryTitle)),
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
                message: l10n.documentHistoryLoadError,
                onRetry: () => ref.invalidate(documentHistoryProvider(documentId)),
              ),
            ),
          ),
          data: (events) {
            if (events.isEmpty) {
              return Center(child: Text(l10n.documentHistoryEmptyState, style: AppTypography.body));
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
                            Text(_eventTypeLabels(l10n)[event.eventType] ?? event.eventType, style: AppTypography.body),
                            const SizedBox(height: 4),
                            Text(
                              event.userId != null
                                  ? l10n.reminderDetailCreatedByValue(event.userId!)
                                  : l10n.documentHistorySystemLabel,
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
