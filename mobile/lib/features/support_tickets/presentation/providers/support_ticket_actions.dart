import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/support_ticket_repository.dart';
import '../../domain/support_ticket.dart';
import '../../domain/ticket_attachment.dart';
import '../../domain/ticket_message.dart';
import 'support_ticket_detail_providers.dart';
import 'support_ticket_list_provider.dart';

final supportTicketActionsProvider = Provider<SupportTicketActions>(
  (ref) => SupportTicketActions(ref),
);

class SupportTicketActions {
  final Ref _ref;
  const SupportTicketActions(this._ref);

  SupportTicketRepository get _repository =>
      _ref.read(supportTicketRepositoryProvider);

  Future<SupportTicket> create({
    required String subject,
    required String description,
    required String priority,
    required String category,
  }) async {
    final ticket = await _repository.createTicket(
      subject: subject,
      description: description,
      priority: priority,
      category: category,
    );
    _ref.invalidate(supportTicketListProvider);
    return ticket;
  }

  Future<TicketMessage> postMessage({
    required String ticketId,
    required String content,
  }) async {
    final message = await _repository.postMessage(
      id: ticketId,
      content: content,
    );
    _ref.invalidate(supportTicketMessagesProvider(ticketId));
    return message;
  }

  Future<TicketAttachment> uploadAttachment({
    required String ticketId,
    required String filePath,
    required String fileName,
  }) async {
    final attachment = await _repository.uploadAttachment(
      id: ticketId,
      filePath: filePath,
      fileName: fileName,
    );
    _ref.invalidate(supportTicketAttachmentsProvider(ticketId));
    return attachment;
  }

  Future<void> deleteAttachment({
    required String ticketId,
    required String attachmentId,
  }) async {
    await _repository.deleteAttachment(
      id: ticketId,
      attachmentId: attachmentId,
    );
    _ref.invalidate(supportTicketAttachmentsProvider(ticketId));
  }
}
