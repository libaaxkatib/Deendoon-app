import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/attachment.dart';

final attachmentApiProvider = Provider<AttachmentApi>((ref) => AttachmentApi(ref.read(dioProvider)));

/// Thin wrapper around `GET/POST {entityPathPrefix}/attachments` — mirrors
/// `CustomerController`/`DebtController`/`CollectionCaseController`'s
/// `attachmentsIndex`/`attachmentsStore` exactly (P1.6). [entityPathPrefix]
/// is e.g. `'customers/$customerId'`, `'debts/$debtId'`, or
/// `'collection-cases/$caseId'` — the three real REST resources this
/// backs.
class AttachmentApi {
  final Dio _dio;

  const AttachmentApi(this._dio);

  Future<List<Attachment>> list(String entityPathPrefix) async {
    final response = await _dio.get('$entityPathPrefix/attachments');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => Attachment.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `mimes:pdf,jpg,jpeg,png,doc,docx`, `max:10240` (10MB) — same
  /// validation on all three backend endpoints. `description` is
  /// optional, max 255 chars server-side.
  Future<Attachment> upload({
    required String entityPathPrefix,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'description': ?description,
    });
    final response = await _dio.post('$entityPathPrefix/attachments', data: formData);
    return Attachment.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
