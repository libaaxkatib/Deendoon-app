import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/deendoon_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attachments/presentation/providers/attachment_providers.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/support_ticket.dart';
import '../../domain/ticket_attachment.dart';
import '../../domain/ticket_message.dart';
import '../providers/support_ticket_actions.dart';
import '../providers/support_ticket_detail_providers.dart';
import '../widgets/ticket_priority_badge.dart';

/// Support Ticket detail — combines the ticket's header info, attachments,
/// and conversation into one scrollable screen (the smallest sensible V1
/// shape: unlike the Admin Panel, the Business Owner has no status-change/
/// close/reopen controls to render here at all — those are Platform
/// Administrator-only actions per Decisions 2/9, so attempting them would
/// only ever fail a 403; this screen only ever *displays* status).
class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _replyController = TextEditingController();
  bool _isSending = false;
  bool _isUploading = false;
  final Set<String> _deletingAttachmentIds = {};

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSending = true);
    try {
      await ref
          .read(supportTicketActionsProvider)
          .postMessage(ticketId: widget.ticketId, content: content);
      _replyController.clear();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final messenger = ScaffoldMessenger.of(context);
    final file = await ref.read(attachmentFilePickerProvider)();
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      await ref
          .read(supportTicketActionsProvider)
          .uploadAttachment(
            ticketId: widget.ticketId,
            filePath: file.path,
            fileName: file.name,
          );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Mobile Fix #4A — the backend is the sole authority on whether this
  /// delete is allowed (ownership, closed-ticket rule); this confirms
  /// intent and surfaces whatever real error comes back, rather than
  /// duplicating either rule client-side.
  Future<void> _deleteAttachment(TicketAttachment attachment) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.attachmentDeleteTitle),
        content: Text(l10n.attachmentDeleteDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.attachmentDeleteConfirmButton,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deletingAttachmentIds.add(attachment.id));
    try {
      await ref
          .read(supportTicketActionsProvider)
          .deleteAttachment(
            ticketId: widget.ticketId,
            attachmentId: attachment.id,
          );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.attachmentDeletedSuccessfully)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _deletingAttachmentIds.remove(attachment.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticketAsync = ref.watch(supportTicketDetailProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ticketAsync.valueOrNull?.referenceNumber ??
              l10n.supportTicketDetailTitle,
        ),
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: RetrySection(
            message: l10n.supportTicketDetailLoadError,
            onRetry: () =>
                ref.invalidate(supportTicketDetailProvider(widget.ticketId)),
          ),
        ),
        data: (ticket) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _TicketHeaderCard(ticket: ticket),
                  const SizedBox(height: 16),
                  _AttachmentsSection(
                    ticketId: widget.ticketId,
                    isClosed: ticket.isClosed,
                    isUploading: _isUploading,
                    onUpload: _pickAndUpload,
                    deletingAttachmentIds: _deletingAttachmentIds,
                    onDelete: _deleteAttachment,
                  ),
                  const SizedBox(height: 16),
                  _ConversationSection(ticketId: widget.ticketId),
                ],
              ),
            ),
            if (!ticket.isClosed)
              SafeArea(
                minimum: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: l10n.supportTicketReplyHint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: AppColors.primary,
                            ),
                            onPressed: _sendReply,
                          ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.supportTicketClosedNotice,
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketHeaderCard extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketHeaderCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: AppTypography.heading.copyWith(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(status: ticket.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TicketPriorityBadge(priority: ticket.priority),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticketCategoryLabel(l10n, ticket.category),
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.description,
            style: AppTypography.body.copyWith(
              color: context.colors.textPrimary,
            ),
          ),
          if (ticket.isClosed && ticket.closedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              l10n.supportTicketClosedAtLabel(
                ticket.closedAt!.split('T').first,
              ),
              style: AppTypography.caption,
            ),
          ],
          if (ticket.reopenedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.supportTicketReopenedAtLabel(
                ticket.reopenedAt!.split('T').first,
              ),
              style: AppTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentsSection extends ConsumerWidget {
  final String ticketId;
  final bool isClosed;
  final bool isUploading;
  final VoidCallback onUpload;
  final Set<String> deletingAttachmentIds;
  final ValueChanged<TicketAttachment> onDelete;

  const _AttachmentsSection({
    required this.ticketId,
    required this.isClosed,
    required this.isUploading,
    required this.onUpload,
    required this.deletingAttachmentIds,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final attachmentsAsync = ref.watch(
      supportTicketAttachmentsProvider(ticketId),
    );
    final authState = ref.watch(authProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.supportTicketAttachmentsTitle, style: AppTypography.body),
          const SizedBox(height: 8),
          attachmentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => Text(
              l10n.supportTicketAttachmentsLoadError,
              style: AppTypography.caption,
            ),
            data: (attachments) => attachments.isEmpty
                ? Text(
                    l10n.supportTicketNoAttachments,
                    style: AppTypography.caption,
                  )
                : Column(
                    children: [
                      for (final attachment in attachments)
                        _AttachmentRow(
                          attachment: attachment,
                          // Deletion is also blocked once the ticket is
                          // closed (SupportTicketAttachmentPolicy) — hide
                          // the action entirely rather than showing it and
                          // relying on a 403.
                          canDelete:
                              !isClosed &&
                              currentUserId != null &&
                              attachment.uploadedByUserId == currentUserId,
                          isDeleting: deletingAttachmentIds.contains(
                            attachment.id,
                          ),
                          onDelete: () => onDelete(attachment),
                        ),
                    ],
                  ),
          ),
          if (!isClosed) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isUploading ? null : onUpload,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file, size: 18),
              label: Text(l10n.supportTicketUploadButton),
            ),
          ],
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  final TicketAttachment attachment;
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback onDelete;

  const _AttachmentRow({
    required this.attachment,
    required this.canDelete,
    required this.isDeleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              attachment.originalFilename,
              style: AppTypography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.danger,
                      size: 18,
                    ),
                    tooltip: l10n.attachmentDeleteTitle,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                  ),
          ],
        ],
      ),
    );
  }
}

class _ConversationSection extends ConsumerWidget {
  final String ticketId;

  const _ConversationSection({required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final messagesAsync = ref.watch(supportTicketMessagesProvider(ticketId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.supportTicketConversationTitle, style: AppTypography.body),
          const SizedBox(height: 8),
          messagesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => Text(
              l10n.supportTicketConversationLoadError,
              style: AppTypography.caption,
            ),
            data: (messages) => messages.isEmpty
                ? Text(
                    l10n.supportTicketNoRepliesYet,
                    style: AppTypography.caption,
                  )
                : Column(
                    children: [
                      for (final message in messages)
                        _MessageBubble(
                          message: message,
                          isOwnMessage:
                              currentUserId != null &&
                              message.senderUserId == currentUserId,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  final bool isOwnMessage;

  const _MessageBubble({required this.message, required this.isOwnMessage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwnMessage
                        ? l10n.supportTicketMessageSenderYou
                        : l10n.supportTicketMessageSenderDeendoon,
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: AppTypography.body.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.createdAt.split('T').first,
                    style: AppTypography.caption,
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
