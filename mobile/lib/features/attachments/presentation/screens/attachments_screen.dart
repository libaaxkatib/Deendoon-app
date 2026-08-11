import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/attachment_repository.dart';
import '../providers/attachment_providers.dart';

/// Generic Attachments screen — backs Customer/Debt/CollectionCase
/// Attachments alike (P1.6), since all three real endpoints
/// (`{entity}/{id}/attachments`) share the identical shape and rules.
/// [canUpload] reflects the caller's own read-only knowledge where
/// available (e.g. Customer Detail already knows `customer.isReadOnly`);
/// when the caller can't cheaply know it (e.g. Debt/Case screens that
/// would need an extra fetch just for this), pass `true` and let the
/// backend's real 403 surface inline — never duplicated client-side
/// logic guessing at the read-only rule.
class AttachmentsScreen extends ConsumerStatefulWidget {
  final String entityPathPrefix;
  final bool canUpload;

  const AttachmentsScreen({super.key, required this.entityPathPrefix, this.canUpload = true});

  @override
  ConsumerState<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends ConsumerState<AttachmentsScreen> {
  bool _isUploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);

    final file = await ref.read(attachmentFilePickerProvider)();
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      await ref.read(attachmentRepositoryProvider).uploadAttachment(
            entityPathPrefix: widget.entityPathPrefix,
            filePath: file.path,
            fileName: file.name,
          );
      ref.invalidate(attachmentsProvider(widget.entityPathPrefix));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final attachmentsAsync = ref.watch(attachmentsProvider(widget.entityPathPrefix));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customerDetailAttachmentsButton)),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(attachmentsProvider(widget.entityPathPrefix));
                await ref.read(attachmentsProvider(widget.entityPathPrefix).future);
              },
              child: attachmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: l10n.professionalCollectionAttachmentsLoadError,
                    onRetry: () => ref.invalidate(attachmentsProvider(widget.entityPathPrefix)),
                  ),
                ),
                data: (attachments) {
                  if (attachments.isEmpty) {
                    return Center(child: Text(l10n.professionalCollectionAttachmentsEmptyState, style: AppTypography.body));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: attachments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final attachment = attachments[index];
                      return AppCard(
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(attachment.originalFilename, style: AppTypography.body),
                                  if (attachment.description != null && attachment.description!.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(attachment.description!, style: AppTypography.caption),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(attachment.createdAt.split('T').first, style: AppTypography.caption),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (widget.canUpload)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 8),
                    ],
                    PrimaryButton(
                      label: l10n.professionalCollectionUploadAttachmentButton,
                      isLoading: _isUploading,
                      onPressed: _pickAndUpload,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
