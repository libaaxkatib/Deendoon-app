import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/professional_collection_detail_providers.dart';

/// Professional Collection Request's "Timeline" destination —
/// `GET /professional-requests/{id}/timeline` — the Deendoon Recovery
/// Team's own operational activity log. Read-only for the Business
/// Owner: `createTimelineEvent`/`updateTimelineEvent` are Deendoon
/// Platform Administrator-only, so no write UI exists here.
class ProfessionalCollectionTimelineScreen extends ConsumerWidget {
  final String requestId;

  const ProfessionalCollectionTimelineScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(professionalCollectionTimelineProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(professionalCollectionTimelineProvider(requestId));
          await ref.read(professionalCollectionTimelineProvider(requestId).future);
        },
        child: timelineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: RetrySection(
              message: 'Could not load the timeline.',
              onRetry: () => ref.invalidate(professionalCollectionTimelineProvider(requestId)),
            ),
          ),
          data: (events) {
            if (events.isEmpty) {
              return const Center(child: Text('No timeline events yet', style: AppTypography.body));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(event.eventType, style: AppTypography.body)),
                          Text(event.occurredAt.split('T').first, style: AppTypography.caption),
                        ],
                      ),
                      if (event.notes != null && event.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(event.notes!, style: AppTypography.caption),
                      ],
                      if (event.outcome != null && event.outcome!.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Outcome: ${event.outcome}',
                          style: AppTypography.caption.copyWith(color: AppColors.primary),
                        ),
                      ],
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
