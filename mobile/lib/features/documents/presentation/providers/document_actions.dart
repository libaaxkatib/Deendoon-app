import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/models/sent_message.dart';
import '../../data/document_repository.dart';

final documentActionsProvider = Provider<DocumentActions>((ref) => DocumentActions(ref));

/// The real, backend-supported Document actions: fetching the raw PDF
/// bytes for in-app Preview, saving them to the device for Download
/// (§8.7 — "every download of a document is recorded against that
/// document's history for audit purposes," handled entirely server-side
/// by `DocumentController::download()`'s own call to
/// `DocumentService::recordDownload()` — no separate client-side call
/// needed), and Share (§8.8, `POST /documents/{id}/share`).
class DocumentActions {
  final Ref _ref;

  const DocumentActions(this._ref);

  DocumentRepository get _repository => _ref.read(documentRepositoryProvider);

  Future<List<int>> fetchBytes(String documentId) => _repository.downloadDocument(documentId);

  /// Saves the already-fetched PDF bytes to the app's own documents
  /// directory (via `path_provider` — no separate file-picker/permission
  /// package added, since this directory needs no runtime permission on
  /// either platform) and returns the saved file's path.
  Future<String> saveToDevice({required String referenceNumber, required List<int> bytes}) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$referenceNumber.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<SentMessage> share({required String documentId, required String channel, required String templateId}) =>
      _repository.shareDocument(id: documentId, channel: channel, templateId: templateId);
}
