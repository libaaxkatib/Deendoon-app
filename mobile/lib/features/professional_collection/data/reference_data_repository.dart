import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/reference_data_item.dart';
import 'reference_data_api.dart';

final referenceDataRepositoryProvider = Provider<ReferenceDataRepository>(
  (ref) => ReferenceDataRepository(ref.read(referenceDataApiProvider)),
);

/// Translates raw Dio failures into `ApiException` — same pattern as every
/// other repository in the app. No caching, no business logic.
class ReferenceDataRepository {
  final ReferenceDataApi _api;

  const ReferenceDataRepository(this._api);

  Future<List<ReferenceDataItem>> fetchCategory(String category) =>
      _guard(() => _api.forCategory(category));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
