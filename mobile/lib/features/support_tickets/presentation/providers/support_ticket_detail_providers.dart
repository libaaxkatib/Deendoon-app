import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/support_ticket_repository.dart';
import '../../domain/support_ticket.dart';
import '../../domain/ticket_attachment.dart';
import '../../domain/ticket_message.dart';

final supportTicketDetailProvider =
    FutureProvider.family<SupportTicket, String>(
      (ref, ticketId) =>
          ref.watch(supportTicketRepositoryProvider).fetchTicket(ticketId),
    );

final supportTicketMessagesProvider =
    FutureProvider.family<List<TicketMessage>, String>(
      (ref, ticketId) =>
          ref.watch(supportTicketRepositoryProvider).fetchMessages(ticketId),
    );

final supportTicketAttachmentsProvider =
    FutureProvider.family<List<TicketAttachment>, String>(
      (ref, ticketId) =>
          ref.watch(supportTicketRepositoryProvider).fetchAttachments(ticketId),
    );
