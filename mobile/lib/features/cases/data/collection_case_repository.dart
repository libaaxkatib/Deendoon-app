import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/case_history.dart';
import '../domain/collection_case.dart';
import '../domain/collection_case_page.dart';
import 'collection_case_api.dart';

final collectionCaseRepositoryProvider =
    Provider<CollectionCaseRepository>((ref) => CollectionCaseRepository(ref.read(collectionCaseApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as
/// every other repository in the app. No caching, no business logic.
class CollectionCaseRepository {
  final CollectionCaseApi _api;

  const CollectionCaseRepository(this._api);

  Future<CollectionCasePage> fetchCases({required int page, String? tab}) =>
      _guard(() => _api.list(page: page, tab: tab));

  Future<CollectionCase> fetchCase(String id) => _guard(() => _api.show(id));

  Future<void> recordActivity({required String caseId, String? details}) =>
      _guard(() => _api.recordActivity(caseId: caseId, details: details));

  Future<CollectionCase> close({required String caseId, required String closureOutcome}) =>
      _guard(() => _api.close(caseId: caseId, closureOutcome: closureOutcome));

  Future<CaseHistory> fetchHistory(String caseId) => _guard(() => _api.history(caseId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
