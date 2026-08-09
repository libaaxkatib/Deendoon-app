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

  Future<CollectionCasePage> fetchCases({required int page, String? tab, String? customerId}) =>
      _guard(() => _api.list(page: page, tab: tab, customerId: customerId));

  /// Flat, unpaginated read for the Customer Detail screen's "Cases" list —
  /// same style as `CustomerRepository.fetchDocuments`/`fetchPayments`
  /// (a customer realistically has few enough cases that infinite-scroll
  /// pagination isn't warranted here).
  Future<List<CollectionCase>> fetchCasesForCustomer(String customerId) async {
    final page = await _guard(() => _api.list(page: 1, customerId: customerId));
    return page.cases;
  }

  Future<CollectionCase> fetchCase(String id) => _guard(() => _api.show(id));

  Future<void> recordActivity({required String caseId, String? details}) =>
      _guard(() => _api.recordActivity(caseId: caseId, details: details));

  Future<CollectionCase> close({required String caseId, required String closureOutcome}) =>
      _guard(() => _api.close(caseId: caseId, closureOutcome: closureOutcome));

  Future<CaseHistory> fetchHistory(String caseId) => _guard(() => _api.history(caseId));

  Future<CollectionCase> updateNotes({required String caseId, String? notes}) =>
      _guard(() => _api.updateNotes(caseId: caseId, notes: notes));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
