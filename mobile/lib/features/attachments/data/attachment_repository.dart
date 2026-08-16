import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/attachment.dart';
import 'attachment_api.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => AttachmentRepository(ref.read(attachmentApiProvider)),
);

/// Translates raw Dio failures into `ApiException` — same pattern as
/// every other repository in the app. No caching, no business logic.
class AttachmentRepository {
  final AttachmentApi _api;

  const AttachmentRepository(this._api);

  Future<List<Attachment>> fetchAttachments(String entityPathPrefix) =>
      _guard(() => _api.list(entityPathPrefix));

  Future<Attachment> uploadAttachment({
    required String entityPathPrefix,
    required String filePath,
    required String fileName,
    String? description,
  }) => _guard(
    () => _api.upload(
      entityPathPrefix: entityPathPrefix,
      filePath: filePath,
      fileName: fileName,
      description: description,
    ),
  );

  Future<void> deleteAttachment(String entityPathPrefix, String attachmentId) =>
      _guard(() => _api.delete(entityPathPrefix, attachmentId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
