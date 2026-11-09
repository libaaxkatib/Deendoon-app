import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/attachment.dart';

final attachmentApiProvider = Provider<AttachmentApi>(
  (ref) => AttachmentApi(ref.read(dioProvider)),
);

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
    return data
        .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The backend's `max:10240` rule (10MB), mirrored only so a file that is
  /// certain to be refused is not pushed over a mobile connection first —
  /// the server still enforces the real limit.
  static const maxFileBytes = 10 * 1024 * 1024;

  /// `mimes:pdf,jpg,jpeg,png,doc,docx`, `max:10240` (10MB) — same
  /// validation on all three backend endpoints. `description` is
  /// optional, max 255 chars server-side.
  Future<Attachment> upload({
    required String entityPathPrefix,
    required String filePath,
    required String fileName,
    String? description,
  }) async {
    if (await File(filePath).length() > maxFileBytes) {
      throw const ApiException(
        message:
            'This file is larger than 10 MB. Please choose a smaller file.',
      );
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'description': ?description,
    });
    final response = await _dio.post(
      '$entityPathPrefix/attachments',
      data: formData,
    );

    // A 2xx whose body is not the JSON envelope (e.g. an HTML page from a
    // proxy or from PHP itself) is not a saved attachment — report it
    // instead of failing later with an opaque cast error.
    final body = response.data;
    final data = body is Map<String, dynamic> ? body['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw ApiException(
        message:
            'The server did not accept this upload. Check that the file is '
            '10 MB or smaller, then try again.',
        statusCode: response.statusCode,
      );
    }
    return Attachment.fromJson(data);
  }

  /// Mobile Fix #4A — `DELETE {entityPathPrefix}/attachments/{id}`, mirrors
  /// `CustomerController`/`DebtController`/`CollectionCaseController`'s
  /// `attachmentsDestroy` exactly. The backend enforces ownership and
  /// workflow-state rules; this call surfaces whatever real error comes
  /// back rather than duplicating that logic client-side.
  Future<void> delete(String entityPathPrefix, String attachmentId) async {
    await _dio.delete('$entityPathPrefix/attachments/$attachmentId');
  }
}
