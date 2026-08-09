import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/network/dio_client.dart';
import '../domain/professional_collection_attachment.dart';
import '../domain/professional_collection_request.dart';
import '../domain/professional_collection_request_page.dart';
import '../domain/professional_collection_summary.dart';
import '../domain/professional_collection_timeline_event.dart';
import '../domain/request_message.dart';

final professionalCollectionApiProvider =
    Provider<ProfessionalCollectionApi>((ref) => ProfessionalCollectionApi(ref.read(dioProvider)));

/// Thin wrapper around `GET/POST /professional-requests*` and
/// `POST /collection-cases/{case}/professional-requests` — mirrors
/// `App\Http\Controllers\ProfessionalCollectionRequestController` exactly.
///
/// Business Owner scope only (`ProfessionalCollectionRequestPolicy`):
/// submit, list, show, and messages are reachable; `transitionStatus`/
/// `close` are Deendoon-Platform-Administrator-only and are deliberately
/// not wrapped here — calling them as a Business Owner always 403s.
class ProfessionalCollectionApi {
  final Dio _dio;

  const ProfessionalCollectionApi(this._dio);

  /// `SubmitProfessionalCollectionRequestRequest`: `reasons` (array,
  /// min 1, each a value from the tenant's own active `transfer_reason`
  /// Reference Data), `services` (array, min 1, `requested_service`
  /// Reference Data), `notes` (nullable, max 2000), `declaration_accepted`
  /// (required, must be true). BRL-078: the backend 409s if the case isn't
  /// open or already has an active (non-terminal) Request; 422s if any
  /// required field is missing — both surfaced to the caller as an
  /// `ApiException` by the repository layer, not handled here.
  Future<ProfessionalCollectionRequest> submit({
    required String caseId,
    required List<String> reasons,
    required List<String> services,
    String? notes,
    required bool declarationAccepted,
  }) async {
    final response = await _dio.post('collection-cases/$caseId/professional-requests', data: {
      'reasons': reasons,
      'services': services,
      'notes': notes,
      'declaration_accepted': declarationAccepted,
    });
    return ProfessionalCollectionRequest.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ProfessionalCollectionRequestPage> list({required int page, String? status}) async {
    final response = await _dio.get('professional-requests', queryParameters: {
      'page': page,
      'status': ?status,
    });
    return ProfessionalCollectionRequestPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ProfessionalCollectionRequest> show(String id) async {
    final response = await _dio.get('professional-requests/$id');
    return ProfessionalCollectionRequest.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `GET /professional-requests/summary` — Business Owner-only (same
  /// `admin-only` gate as Business Health). Registered ahead of `show()`'s
  /// `{id}` route server-side, so "summary" is never swallowed as an id.
  Future<ProfessionalCollectionSummary> summary() async {
    final response = await _dio.get('professional-requests/summary');
    return ProfessionalCollectionSummary.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<RequestMessage>> messages(String id) async {
    final response = await _dio.get('professional-requests/$id/messages');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => RequestMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `PostRequestMessageRequest`: `content` required, max 5000 chars.
  /// BRL-080/DD-044: 409s if the Request is already terminal — surfaced as
  /// an `ApiException`, not handled here.
  Future<RequestMessage> postMessage({required String id, required String content}) async {
    final response = await _dio.post('professional-requests/$id/messages', data: {'content': content});
    return RequestMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `GET /professional-requests/{id}/documents` — the existing Receipt/
  /// DemandLetter/Statement/Invoice rows auto-linked at submission,
  /// resolved to their own real Resources. All 4 share the identical
  /// shape already modeled by `DocumentSummary` — reused as-is, not
  /// duplicated.
  Future<List<DocumentSummary>> documents(String id) async {
    final response = await _dio.get('professional-requests/$id/documents');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => DocumentSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProfessionalCollectionAttachment>> attachments(String id) async {
    final response = await _dio.get('professional-requests/$id/attachments');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => ProfessionalCollectionAttachment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `UploadProfessionalCollectionAttachmentRequest`: `file` required
  /// (`mimes:pdf,jpg,jpeg,png,doc,docx`, `max:10240` — 10MB), optional
  /// `timeline_event_id`. `uploadAttachment()` policy limits when a
  /// Business Owner may call this (pre-Assigned statuses only) — enforced
  /// server-side, not duplicated here.
  Future<ProfessionalCollectionAttachment> uploadAttachment({
    required String id,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post('professional-requests/$id/attachments', data: formData);
    return ProfessionalCollectionAttachment.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `GET /professional-requests/{id}/timeline` — read-only for the
  /// Business Owner; `createTimelineEvent`/`updateTimelineEvent` are
  /// Deendoon Platform Administrator-only, so no write method is wrapped
  /// here.
  Future<List<ProfessionalCollectionTimelineEvent>> timeline(String id) async {
    final response = await _dio.get('professional-requests/$id/timeline');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => ProfessionalCollectionTimelineEvent.fromJson(e as Map<String, dynamic>)).toList();
  }
}
