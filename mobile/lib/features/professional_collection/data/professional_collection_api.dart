import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/professional_collection_request.dart';
import '../domain/professional_collection_request_page.dart';
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

  /// `SubmitProfessionalCollectionRequestRequest` — bare, no fields.
  /// BRL-078: the backend 409s if the case isn't open or already has an
  /// active (non-terminal) Request; that's surfaced to the caller as an
  /// `ApiException` by the repository layer, not handled here.
  Future<ProfessionalCollectionRequest> submit(String caseId) async {
    final response = await _dio.post('collection-cases/$caseId/professional-requests');
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
}
