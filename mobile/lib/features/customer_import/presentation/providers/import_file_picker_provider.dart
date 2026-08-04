import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'customer_import_provider.dart';

typedef PickedImportFile = ({String path, String name, int size});

/// Isolates the real `file_picker` plugin call behind a provider so widget
/// tests can override it — `file_picker` needs a platform channel that
/// doesn't exist in the widget-test environment.
final importFilePickerProvider = Provider<Future<PickedImportFile?> Function()>((ref) => _pickFile);

Future<PickedImportFile?> _pickFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: importAllowedExtensions,
  );
  final file = result?.files.single;
  if (file == null || file.path == null) return null;
  return (path: file.path!, name: file.name, size: file.size);
}
