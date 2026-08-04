import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/professional_collection_detail_providers.dart';

/// Professional Collection Request Detail — reference number, status,
/// submitted/closed dates, a link back to the originating Collection
/// Case, and a "View Messages" entry point. "Submitted By"/"Actioned By"
/// are shown as raw user ids — there is no endpoint reachable by the
/// Business Owner role to resolve an arbitrary user id to a name (same
/// gap as Assigned Officer on Collection Cases, Created By on Reminders).
/// No Status Transition / Close action here — both are Deendoon-
/// Platform-Administrator-only (`ProfessionalCollectionRequestPolicy`),
/// out of Sprint 20 Unit 1 scope.
class ProfessionalCollectionDetailScreen extends ConsumerWidget {
  final String requestId;

  const ProfessionalCollectionDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(professionalCollectionDetailProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: Text(requestAsync.valueOrNull?.referenceNumber ?? 'Professional Collection Request'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(professionalCollectionDetailProvider(requestId));
          await ref.read(professionalCollectionDetailProvider(requestId).future);
        },
        child: requestAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: 'Could not load this Professional Collection Request.',
                onRetry: () => ref.invalidate(professionalCollectionDetailProvider(requestId)),
              ),
            ),
          ),
          data: (request) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(request.referenceNumber, style: AppTypography.subheading),
                        StatusBadge(status: request.status),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.background),
                    _InfoRow(label: 'Submitted By', value: request.submittedByUserId),
                    if (request.actionedByUserId != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Actioned By', value: request.actionedByUserId!),
                    ],
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Submitted On', value: request.createdAt.split('T').first),
                    if (request.closedAt != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Closed On', value: request.closedAt!.split('T').first),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.push('/cases/${request.collectionCaseId}'),
                child: const Text('View Collection Case'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/professional-requests/$requestId/messages'),
                child: const Text('View Messages'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption),
        Text(value, style: AppTypography.body.copyWith(color: AppColors.primary)),
      ],
    );
  }
}
