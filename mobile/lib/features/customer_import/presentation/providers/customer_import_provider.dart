import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/customer_import_repository.dart';
import '../../domain/customer_import_state.dart';

final customerImportProvider =
    NotifierProvider<CustomerImportNotifier, CustomerImportState>(
      CustomerImportNotifier.new,
    );

/// The backend's `ImportCustomersRequest` accepts only these two
/// extensions (`mimes:xlsx,xls`) — `.csv` is not supported server-side
/// despite being a common import format.
const importAllowedExtensions = ['xlsx', 'xls'];

class CustomerImportNotifier extends Notifier<CustomerImportState> {
  @override
  CustomerImportState build() => const ImportInitial();

  CustomerImportRepository get _repository =>
      ref.read(customerImportRepositoryProvider);

  void selectFile({
    required String path,
    required String name,
    required int size,
    required String unsupportedFileTypeMessage,
  }) {
    final extension = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    if (!importAllowedExtensions.contains(extension)) {
      state = ImportFailed(message: unsupportedFileTypeMessage);
      return;
    }
    state = ImportFileSelected(filePath: path, fileName: name, fileSize: size);
  }

  void clear() => state = const ImportInitial();

  /// Runs the real two-step backend flow back to back: Preview
  /// (`POST /customers/import`) then an immediate Commit with no
  /// per-row resolutions (`POST /customers/import/{batch}/commit`). An
  /// empty `resolutions` list means every duplicate-matched row defaults
  /// to `skip` server-side and every non-duplicate valid row becomes
  /// `new` — the only safe default the backend itself defines, and
  /// exactly what maps onto "Imported / Skipped (Duplicate) / Failed".
  Future<void> startImport() async {
    final current = state;
    if (current is! ImportFileSelected) return;

    state = ImportRunning(fileName: current.fileName);
    try {
      final preview = await _repository.previewImport(
        filePath: current.filePath,
        fileName: current.fileName,
      );
      final result = await _repository.commitImport(batchId: preview.batchId);
      state = ImportSucceeded(preview: preview, result: result);
    } on ApiException catch (e) {
      state = ImportFailed(message: e.message, fieldErrors: e.fieldErrors);
    }
  }
}
