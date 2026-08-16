import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/import_commit_result.dart';
import '../domain/import_preview.dart';

final customerImportApiProvider = Provider<CustomerImportApi>(
  (ref) => CustomerImportApi(ref.read(dioProvider)),
);

/// Thin wrapper around `GET /customers/import/template`,
/// `POST /customers/import`, and `POST /customers/import/{batch}/commit`
/// — mirrors `App\Http\Controllers\CustomerImportController` exactly.
/// There is no progress-polling endpoint (the backend parses and commits
/// synchronously, no queue job backs this).
class CustomerImportApi {
  final Dio _dio;

  const CustomerImportApi(this._dio);

  /// Streams the raw `.xlsx` bytes — same non-JSON-envelope shape as
  /// `DocumentApi.download()` (`CustomerImportController::template()`
  /// returns `Excel::download()`'s raw binary response directly).
  Future<List<int>> downloadTemplate() async {
    final response = await _dio.get<List<int>>(
      'customers/import/template',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  /// `ImportCustomersRequest` accepts only `mimes:xlsx,xls` — the backend
  /// does not accept `.csv` despite it being a common import format.
  Future<ImportPreview> preview({
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post('customers/import', data: formData);
    return ImportPreview.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// `resolutions` left empty means every duplicate-matched row defaults
  /// to `skip` server-side (`CommitCustomerImportRequest` — the field is
  /// `sometimes`, never required).
  Future<ImportCommitResult> commit({required String batchId}) async {
    final response = await _dio.post(
      'customers/import/$batchId/commit',
      data: {'resolutions': []},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return ImportCommitResult.fromJson({
      ...data,
      'message': response.data['message'],
    });
  }
}
