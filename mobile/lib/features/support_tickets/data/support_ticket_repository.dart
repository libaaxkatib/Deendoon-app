import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/support_ticket.dart';
import '../domain/support_ticket_page.dart';
import '../domain/ticket_attachment.dart';
import '../domain/ticket_message.dart';
import 'support_ticket_api.dart';

final supportTicketRepositoryProvider = Provider<SupportTicketRepository>(
  (ref) => SupportTicketRepository(ref.read(supportTicketApiProvider)),
);

class SupportTicketRepository {
  final SupportTicketApi _api;
  const SupportTicketRepository(this._api);

  Future<SupportTicketPage> fetchTickets({required int page, String? status}) =>
      _guard(() => _api.list(page: page, status: status));

  Future<SupportTicket> fetchTicket(String id) => _guard(() => _api.show(id));

  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required String priority,
    required String category,
  }) => _guard(
    () => _api.create(
      subject: subject,
      description: description,
      priority: priority,
      category: category,
    ),
  );

  Future<List<TicketMessage>> fetchMessages(String id) =>
      _guard(() => _api.messages(id));

  Future<TicketMessage> postMessage({
    required String id,
    required String content,
  }) => _guard(() => _api.postMessage(id: id, content: content));

  Future<List<TicketAttachment>> fetchAttachments(String id) =>
      _guard(() => _api.attachments(id));

  Future<TicketAttachment> uploadAttachment({
    required String id,
    required String filePath,
    required String fileName,
  }) => _guard(
    () => _api.uploadAttachment(id: id, filePath: filePath, fileName: fileName),
  );

  Future<void> deleteAttachment({
    required String id,
    required String attachmentId,
  }) => _guard(() => _api.deleteAttachment(id: id, attachmentId: attachmentId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
