import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/case_history.dart';
import '../domain/collection_case.dart';
import '../domain/collection_case_page.dart';

final collectionCaseApiProvider = Provider<CollectionCaseApi>(
  (ref) => CollectionCaseApi(ref.read(dioProvider)),
);

/// Thin wrapper around `GET/PATCH/PUT/POST /collection-cases*` — mirrors
/// `App\Http\Controllers\CollectionCaseController` exactly.
///
/// `GET /collection-cases` supports `status` (`open`/`closed`, not used by
/// this sprint's UI), `tab` (`all`, `high_risk`, `follow_up`,
/// `promise_due` — the four approved filter chips), and `customer_id`
/// (scopes to a single customer's cases, composable with the other two).
/// There is no `search` parameter at all (see the Sprint 13 summary's
/// "Missing Backend Support Required").
class CollectionCaseApi {
  final Dio _dio;

  const CollectionCaseApi(this._dio);

  Future<CollectionCasePage> list({
    required int page,
    String? tab,
    String? customerId,
  }) async {
    final response = await _dio.get(
      'collection-cases',
      queryParameters: {'page': page, 'tab': ?tab, 'customer_id': ?customerId},
    );
    return CollectionCasePage.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<CollectionCase> show(String id) async {
    final response = await _dio.get('collection-cases/$id');
    return CollectionCase.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// `RecordCollectionActivityRequest`: `details` is the only field, an
  /// optional free-text string (max 1000 chars). The backend writes every
  /// call under the same generic `action_type='collection_activity'` —
  /// there is no `type` param distinguishing "Add Follow-up" from "Mark
  /// Contacted" from "Record Visit" server-side.
  Future<void> recordActivity({required String caseId, String? details}) async {
    await _dio.post(
      'collection-cases/$caseId/activities',
      data: {'details': ?details},
    );
  }

  /// `CloseCollectionCaseRequest`: `closure_outcome` required, free text,
  /// max 50 chars — no backend-enforced enum (DD-024 is still pending).
  Future<CollectionCase> close({
    required String caseId,
    required String closureOutcome,
  }) async {
    final response = await _dio.post(
      'collection-cases/$caseId/close',
      data: {'closure_outcome': closureOutcome},
    );
    return CollectionCase.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<CaseHistory> history(String caseId) async {
    final response = await _dio.get('collection-cases/$caseId/history');
    return CaseHistory.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `UpdateCollectionCaseRequest`: `notes` is the only editable field, a
  /// nullable free-text case annotation distinct from the Timeline's
  /// per-activity details.
  Future<CollectionCase> updateNotes({
    required String caseId,
    String? notes,
  }) async {
    final response = await _dio.put(
      'collection-cases/$caseId',
      data: {'notes': notes},
    );
    return CollectionCase.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
