import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/support_ticket.dart';
import '../domain/support_ticket_page.dart';
import '../domain/ticket_attachment.dart';
import '../domain/ticket_message.dart';

final supportTicketApiProvider = Provider<SupportTicketApi>(
  (ref) => SupportTicketApi(ref.read(dioProvider)),
);

class SupportTicketApi {
  final Dio _dio;
  const SupportTicketApi(this._dio);

  Future<SupportTicketPage> list({required int page, String? status}) async {
    final response = await _dio.get(
      'support-tickets',
      queryParameters: {'page': page, 'perPage': 15, 'status': ?status},
    );
    return SupportTicketPage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<SupportTicket> show(String id) async {
    final response = await _dio.get('support-tickets/$id');
    return SupportTicket.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<SupportTicket> create({
    required String subject,
    required String description,
    required String priority,
    required String category,
  }) async {
    final response = await _dio.post(
      'support-tickets',
      data: {
        'subject': subject,
        'description': description,
        'priority': priority,
        'category': category,
      },
    );
    return SupportTicket.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<TicketMessage>> messages(String id) async {
    final response = await _dio.get('support-tickets/$id/messages');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TicketMessage> postMessage({
    required String id,
    required String content,
  }) async {
    final response = await _dio.post(
      'support-tickets/$id/messages',
      data: {'content': content},
    );
    return TicketMessage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<TicketAttachment>> attachments(String id) async {
    final response = await _dio.get('support-tickets/$id/attachments');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => TicketAttachment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TicketAttachment> uploadAttachment({
    required String id,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post(
      'support-tickets/$id/attachments',
      data: formData,
    );
    return TicketAttachment.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Mobile Fix #4A — `DELETE support-tickets/{id}/attachments/{attachment}`,
  /// mirrors `SupportTicketController::attachmentsDestroy` exactly.
  Future<void> deleteAttachment({
    required String id,
    required String attachmentId,
  }) async {
    await _dio.delete('support-tickets/$id/attachments/$attachmentId');
  }
}
