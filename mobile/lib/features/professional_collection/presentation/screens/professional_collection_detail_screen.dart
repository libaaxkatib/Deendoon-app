import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/unavailable_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/professional_collection_detail_providers.dart';

/// Professional Collection Request Detail — reference number, status,
/// submitted/closed dates, the Reasons for Transfer/Requested
/// Services/Notes/Client Declaration record collected at submission
/// (FR-072/FR-074), a link back to the originating Collection Case, and a
/// "View Messages" entry point. "Submitted By"/"Actioned By"/"Declaration
/// Accepted By" are shown as raw user ids — there is no endpoint reachable
/// by the Business Owner role to resolve an arbitrary user id to a name
/// (same gap as Assigned Officer on Collection Cases, Created By on
/// Reminders). No Status Transition / Close action here — both are
/// Deendoon-Platform-Administrator-only
/// (`ProfessionalCollectionRequestPolicy`).
class ProfessionalCollectionDetailScreen extends ConsumerWidget {
  final String requestId;

  const ProfessionalCollectionDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestAsync = ref.watch(professionalCollectionDetailProvider(requestId));

    return Scaffold(
      appBar: AppBar(
        title: Text(requestAsync.valueOrNull?.referenceNumber ?? l10n.professionalCollectionDetailTitle),
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
                message: l10n.professionalCollectionDetailLoadError,
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
                        Text(
                          request.referenceNumber,
                          style: AppTypography.subheading.copyWith(color: context.colors.textPrimary),
                        ),
                        StatusBadge(status: request.status),
                      ],
                    ),
                    Divider(height: 32, color: context.colors.background),
                    _InfoRow(label: l10n.professionalCollectionSubmittedByLabel, value: request.submittedByUserId),
                    if (request.actionedByUserId != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(label: l10n.professionalCollectionActionedByLabel, value: request.actionedByUserId!),
                    ],
                    const SizedBox(height: 12),
                    _InfoRow(
                      label: l10n.professionalCollectionSubmittedOnLabel,
                      value: request.createdAt.split('T').first,
                    ),
                    if (request.closedAt != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: l10n.professionalCollectionClosedOnLabel,
                        value: request.closedAt!.split('T').first,
                      ),
                    ],
                    if (request.declarationAcceptedAt != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: l10n.professionalCollectionDeclarationAcceptedLabel,
                        value: request.declarationAcceptedAt!.split('T').first,
                      ),
                    ],
                    if (request.declarationAcceptedBy != null) ...[
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: l10n.professionalCollectionDeclarationAcceptedByLabel,
                        value: request.declarationAcceptedBy!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.professionalCollectionReasonsForTransferHeading,
                style: AppTypography.heading.copyWith(color: context.colors.textPrimary),
              ),
              const SizedBox(height: 12),
              if (request.reasons.isEmpty)
                UnavailableSection(reason: l10n.professionalCollectionNoReasonsRecorded)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final reason in request.reasons) Chip(label: Text(reason))],
                ),
              const SizedBox(height: 24),
              Text(
                l10n.professionalCollectionRequestedServicesHeading,
                style: AppTypography.heading.copyWith(color: context.colors.textPrimary),
              ),
              const SizedBox(height: 12),
              if (request.requestedServices.isEmpty)
                UnavailableSection(reason: l10n.professionalCollectionNoRequestedServicesRecorded)
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final service in request.requestedServices) Chip(label: Text(service))],
                ),
              const SizedBox(height: 24),
              Text(
                l10n.addEditDebtNotesHeading,
                style: AppTypography.heading.copyWith(color: context.colors.textPrimary),
              ),
              const SizedBox(height: 12),
              if (request.notes == null || request.notes!.trim().isEmpty)
                UnavailableSection(reason: l10n.professionalCollectionNoNotesRecorded)
              else
                AppCard(
                  child: Text(
                    request.notes!,
                    style: AppTypography.body.copyWith(color: context.colors.textPrimary),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.push('/cases/${request.collectionCaseId}'),
                child: Text(l10n.professionalCollectionViewCaseButton),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/professional-requests/$requestId/documents'),
                      child: Text(l10n.navDocuments),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/professional-requests/$requestId/attachments'),
                      child: Text(l10n.customerDetailAttachmentsButton),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/professional-requests/$requestId/timeline'),
                child: Text(l10n.professionalCollectionViewTimelineButton),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/professional-requests/$requestId/messages'),
                child: Text(l10n.professionalCollectionViewMessagesButton),
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
        Text(label, style: AppTypography.caption.copyWith(color: context.colors.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body.copyWith(color: AppColors.primary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
