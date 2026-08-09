import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../attachments/presentation/providers/attachment_providers.dart';
import '../providers/professional_collection_actions.dart';
import '../providers/professional_collection_detail_providers.dart';

/// Professional Collection Request's "Attachments" destination —
/// `GET/POST /professional-requests/{id}/attachments`
/// (`UploadProfessionalCollectionAttachmentRequest`:
/// `mimes:pdf,jpg,jpeg,png,doc,docx`, `max:10240` — 10MB). Upload is only
/// offered pre-Assigned (`submitted`/`under_review`/
/// `need_more_information`/`accepted`) — once `assigned`/`in_progress` the
/// Deendoon Platform Administrator takes over uploads, and once
/// `recovered`/`closed` nobody may upload — matching
/// `ProfessionalCollectionRequestPolicy::uploadAttachment()` exactly.
/// Viewing/downloading (not implemented in the mobile app for arbitrary
/// uploaded files — no dedicated preview endpoint) stays available
/// throughout via the file list itself.
class ProfessionalCollectionAttachmentsScreen extends ConsumerStatefulWidget {
  final String requestId;

  const ProfessionalCollectionAttachmentsScreen({super.key, required this.requestId});

  @override
  ConsumerState<ProfessionalCollectionAttachmentsScreen> createState() =>
      _ProfessionalCollectionAttachmentsScreenState();
}

class _ProfessionalCollectionAttachmentsScreenState extends ConsumerState<ProfessionalCollectionAttachmentsScreen> {
  bool _isUploading = false;
  String? _error;

  static const _canUploadStatuses = {'submitted', 'under_review', 'need_more_information', 'accepted'};

  Future<void> _pickAndUpload() async {
    setState(() => _error = null);

    final file = await ref.read(attachmentFilePickerProvider)();
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      await ref.read(professionalCollectionActionsProvider).uploadAttachment(
            requestId: widget.requestId,
            filePath: file.path,
            fileName: file.name,
          );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(professionalCollectionAttachmentsProvider(widget.requestId));
    final requestAsync = ref.watch(professionalCollectionDetailProvider(widget.requestId));
    final canUpload = _canUploadStatuses.contains(requestAsync.valueOrNull?.status);

    return Scaffold(
      appBar: AppBar(title: const Text('Attachments')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(professionalCollectionAttachmentsProvider(widget.requestId));
                await ref.read(professionalCollectionAttachmentsProvider(widget.requestId).future);
              },
              child: attachmentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: RetrySection(
                    message: 'Could not load attachments.',
                    onRetry: () => ref.invalidate(professionalCollectionAttachmentsProvider(widget.requestId)),
                  ),
                ),
                data: (attachments) {
                  if (attachments.isEmpty) {
                    return const Center(child: Text('No attachments yet', style: AppTypography.body));
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
          if (canUpload)
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
                    PrimaryButton(label: 'Upload Attachment', isLoading: _isUploading, onPressed: _pickAndUpload),
                  ],
                ),
              ),
            )
          else if (requestAsync.hasValue)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Uploading is not available at this stage of the Request.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
