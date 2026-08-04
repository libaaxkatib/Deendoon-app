import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/professional_collection_request.dart';
import '../domain/professional_collection_request_page.dart';
import '../domain/request_message.dart';
import 'professional_collection_api.dart';

final professionalCollectionRepositoryProvider = Provider<ProfessionalCollectionRepository>(
  (ref) => ProfessionalCollectionRepository(ref.read(professionalCollectionApiProvider)),
);

/// Translates raw Dio failures into `ApiException` — same pattern as every
/// other repository in the app. No caching, no calculation.
class ProfessionalCollectionRepository {
  final ProfessionalCollectionApi _api;

  const ProfessionalCollectionRepository(this._api);

  Future<ProfessionalCollectionRequest> submit(String caseId) => _guard(() => _api.submit(caseId));

  Future<ProfessionalCollectionRequestPage> fetchRequests({required int page, String? status}) =>
      _guard(() => _api.list(page: page, status: status));

  Future<ProfessionalCollectionRequest> fetchRequest(String id) => _guard(() => _api.show(id));

  Future<List<RequestMessage>> fetchMessages(String id) => _guard(() => _api.messages(id));

  Future<RequestMessage> postMessage({required String id, required String content}) =>
      _guard(() => _api.postMessage(id: id, content: content));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
