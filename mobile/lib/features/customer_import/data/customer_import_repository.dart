import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/import_commit_result.dart';
import '../domain/import_preview.dart';
import 'customer_import_api.dart';

final customerImportRepositoryProvider =
    Provider<CustomerImportRepository>((ref) => CustomerImportRepository(ref.read(customerImportApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as every
/// other repository in the app. No caching, no business logic.
class CustomerImportRepository {
  final CustomerImportApi _api;

  const CustomerImportRepository(this._api);

  Future<ImportPreview> previewImport({required String filePath, required String fileName}) =>
      _guard(() => _api.preview(filePath: filePath, fileName: fileName));

  Future<ImportCommitResult> commitImport({required String batchId}) => _guard(() => _api.commit(batchId: batchId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
