import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/attachment_repository.dart';
import '../../domain/attachment.dart';

/// Family-keyed by `entityPathPrefix` (e.g. `'customers/01ABC'`) — the
/// same one repository/provider pair backs Customer/Debt/CollectionCase
/// attachments, since all three are identical in shape (P1.6).
final attachmentsProvider = FutureProvider.family<List<Attachment>, String>(
  (ref, entityPathPrefix) => ref.watch(attachmentRepositoryProvider).fetchAttachments(entityPathPrefix),
);

typedef PickedAttachmentFile = ({String path, String name});

/// Isolates the real `file_picker` plugin call behind a provider so widget
/// tests can override it — same rationale as `importFilePickerProvider`
/// (`file_picker` needs a platform channel that doesn't exist in the
/// widget-test environment).
final attachmentFilePickerProvider = Provider<Future<PickedAttachmentFile?> Function()>((ref) => _pickFile);

Future<PickedAttachmentFile?> _pickFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
  );
  final file = result?.files.single;
  if (file == null || file.path == null) return null;
  return (path: file.path!, name: file.name);
}

/// Scan Invoice (P2.6) — same isolation rationale as
/// [attachmentFilePickerProvider]: `image_picker` needs a platform channel
/// that doesn't exist in the widget-test environment. V1 scope only:
/// captures a photo and uploads it as a plain attachment — no OCR, no
/// invoice-data extraction, no manual invoice metadata form (Product
/// Owner decision).
final attachmentCameraProvider = Provider<Future<PickedAttachmentFile?> Function()>((ref) => _captureImage);

Future<PickedAttachmentFile?> _captureImage() async {
  final file = await ImagePicker().pickImage(source: ImageSource.camera);
  if (file == null) return null;
  return (path: file.path, name: file.name);
}
