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
    } on ApiException {
      rethrow;
    } catch (e) {
      // Building the multipart upload reads the picked file from disk
      // (`MultipartFile.fromFile`) before any request is sent — if that
      // file's path has gone stale (e.g. Android reclaimed a picker/camera
      // cache file while the user kept editing the form), this throws a
      // plain FileSystemException, not a DioException. Left uncaught here,
      // it would bypass every caller's `on ApiException` handler entirely
      // and could leave a caller's loading state stuck forever.
      throw const ApiException(
        message: 'Could not upload the file. Please try again.',
      );
    }
  }
}
