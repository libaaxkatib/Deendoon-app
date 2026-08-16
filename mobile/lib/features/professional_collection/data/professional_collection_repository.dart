import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/network/api_exception.dart';
import '../domain/professional_collection_attachment.dart';
import '../domain/professional_collection_request.dart';
import '../domain/professional_collection_request_page.dart';
import '../domain/professional_collection_summary.dart';
import '../domain/professional_collection_timeline_event.dart';
import '../domain/request_message.dart';
import 'professional_collection_api.dart';

final professionalCollectionRepositoryProvider =
    Provider<ProfessionalCollectionRepository>(
      (ref) => ProfessionalCollectionRepository(
        ref.read(professionalCollectionApiProvider),
      ),
    );

/// Translates raw Dio failures into `ApiException` — same pattern as every
/// other repository in the app. No caching, no calculation.
class ProfessionalCollectionRepository {
  final ProfessionalCollectionApi _api;

  const ProfessionalCollectionRepository(this._api);

  Future<ProfessionalCollectionRequest> submit({
    required String caseId,
    required List<String> reasons,
    required List<String> services,
    String? notes,
    required bool declarationAccepted,
  }) => _guard(
    () => _api.submit(
      caseId: caseId,
      reasons: reasons,
      services: services,
      notes: notes,
      declarationAccepted: declarationAccepted,
    ),
  );

  Future<ProfessionalCollectionRequestPage> fetchRequests({
    required int page,
    String? status,
  }) => _guard(() => _api.list(page: page, status: status));

  Future<ProfessionalCollectionRequest> fetchRequest(String id) =>
      _guard(() => _api.show(id));

  Future<ProfessionalCollectionSummary> fetchSummary() =>
      _guard(() => _api.summary());

  Future<List<RequestMessage>> fetchMessages(String id) =>
      _guard(() => _api.messages(id));

  Future<RequestMessage> postMessage({
    required String id,
    required String content,
  }) => _guard(() => _api.postMessage(id: id, content: content));

  Future<List<DocumentSummary>> fetchDocuments(String id) =>
      _guard(() => _api.documents(id));

  Future<List<ProfessionalCollectionAttachment>> fetchAttachments(String id) =>
      _guard(() => _api.attachments(id));

  Future<ProfessionalCollectionAttachment> uploadAttachment({
    required String id,
    required String filePath,
    required String fileName,
  }) => _guard(
    () => _api.uploadAttachment(id: id, filePath: filePath, fileName: fileName),
  );

  Future<List<ProfessionalCollectionTimelineEvent>> fetchTimeline(String id) =>
      _guard(() => _api.timeline(id));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
