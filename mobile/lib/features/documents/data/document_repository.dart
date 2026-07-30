import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/models/sent_message.dart';
import '../../../core/network/api_exception.dart';
import '../domain/document_event.dart';
import '../domain/document_page.dart';
import '../domain/storage_usage.dart';
import 'document_api.dart';

final documentRepositoryProvider =
    Provider<DocumentRepository>((ref) => DocumentRepository(ref.read(documentApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as
/// every other repository in the app. No caching, no business logic.
class DocumentRepository {
  final DocumentApi _api;

  const DocumentRepository(this._api);

  Future<DocumentPage> fetchDocuments({required int page, String? type, String search = ''}) =>
      _guard(() => _api.list(page: page, type: type, search: search));

  Future<StorageUsage> fetchStorageUsage() => _guard(() => _api.storageUsage());

  Future<DocumentSummary> fetchDocument(String id) => _guard(() => _api.show(id));

  Future<List<int>> downloadDocument(String id) => _guard(() => _api.download(id));

  Future<List<DocumentEvent>> fetchHistory(String id) => _guard(() => _api.history(id));

  Future<SentMessage> shareDocument({required String id, required String channel, required String templateId}) =>
      _guard(() => _api.share(id: id, channel: channel, templateId: templateId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
