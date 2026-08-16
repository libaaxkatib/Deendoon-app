import 'import_commit_result.dart';
import 'import_preview.dart';

/// State machine for the Bulk Import flow. There is no backend progress
/// signal to report mid-`ImportRunning` (`CustomerImportController::store`/
/// `commit` are synchronous, not queued jobs) — `ImportRunning` is a plain
/// loading state, not a percentage.
sealed class CustomerImportState {
  const CustomerImportState();
}

class ImportInitial extends CustomerImportState {
  const ImportInitial();
}

class ImportFileSelected extends CustomerImportState {
  final String filePath;
  final String fileName;
  final int fileSize;

  const ImportFileSelected({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });
}

class ImportRunning extends CustomerImportState {
  final String fileName;

  const ImportRunning({required this.fileName});
}

/// `preview` is kept alongside `result` because `commit`'s response
/// carries only `outcome` per row, not the original validation errors —
/// showing why a row was skipped as invalid requires cross-referencing
/// back to the real Preview row.
class ImportSucceeded extends CustomerImportState {
  final ImportPreview preview;
  final ImportCommitResult result;

  const ImportSucceeded({required this.preview, required this.result});
}

class ImportFailed extends CustomerImportState {
  final String message;
  final Map<String, dynamic>? fieldErrors;

  const ImportFailed({required this.message, this.fieldErrors});
}
