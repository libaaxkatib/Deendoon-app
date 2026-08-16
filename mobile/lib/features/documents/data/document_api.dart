import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/models/sent_message.dart';
import '../../../core/network/dio_client.dart';
import '../domain/document_event.dart';
import '../domain/document_page.dart';
import '../domain/storage_usage.dart';

final documentApiProvider = Provider<DocumentApi>(
  (ref) => DocumentApi(ref.read(dioProvider)),
);

/// Thin wrapper around `GET/POST /documents*` — mirrors
/// `App\Http\Controllers\DocumentController` exactly.
///
/// `GET /documents` (the tenant-wide list, §8.1) supports exactly two
/// real query params: `type` (all/invoices/receipts/letters/other —
/// mirrors the 5 approved tabs 1:1) and `search` (matches only against
/// `reference_number`, e.g. "INV-000123" — NOT a customer-name or
/// filename search). There is no `customer_id`/`debt_id`/date-range
/// parameter on this endpoint (see the Sprint 15 summary's "Backend
/// Blockers").
class DocumentApi {
  final Dio _dio;

  const DocumentApi(this._dio);

  Future<DocumentPage> list({
    required int page,
    String? type,
    String search = '',
  }) async {
    final response = await _dio.get(
      'documents',
      queryParameters: {
        'page': page,
        'type': ?type,
        if (search.isNotEmpty) 'search': search,
      },
    );
    return DocumentPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StorageUsage> storageUsage() async {
    final response = await _dio.get('documents/storage-usage');
    return StorageUsage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<DocumentSummary> show(String id) async {
    final response = await _dio.get('documents/$id');
    return DocumentSummary.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// Streams the actual PDF bytes — this endpoint does NOT return the
  /// standard `{success,message,data,errors}` JSON envelope (confirmed by
  /// reading `DocumentController::download()`: it returns a raw
  /// `StreamedResponse` with `Content-Disposition: attachment`), so this
  /// is the one Documents call that reads `response.data` directly as
  /// bytes rather than unwrapping `['data']`.
  Future<List<int>> download(String id) async {
    final response = await _dio.get<List<int>>(
      'documents/$id/download',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<List<DocumentEvent>> history(String id) async {
    final response = await _dio.get('documents/$id/history');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => DocumentEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `DocumentShareRequest`: `channel` + `template_id` only — the
  /// recipient phone is resolved server-side from the document's linked
  /// customer, never client-supplied. Distinct real endpoint from the
  /// Reminder's own `send` (Sprint 14) — confirmed by reading
  /// `DocumentController::share()`/`MessageDeliveryService::
  /// sendDocument()` in full; the two `MessageController` endpoints
  /// (`sendWhatsApp`/`sendSms`) are hard-coded to reminders only and
  /// cannot accept a document.
  Future<SentMessage> share({
    required String id,
    required String channel,
    required String templateId,
  }) async {
    final response = await _dio.post(
      'documents/$id/share',
      data: {'channel': channel, 'template_id': templateId},
    );
    return SentMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
