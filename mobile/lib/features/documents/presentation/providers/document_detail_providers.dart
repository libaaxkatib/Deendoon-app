import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/document_summary.dart';
import '../../data/document_repository.dart';
import '../../domain/storage_usage.dart';

final documentDetailProvider = FutureProvider.family<DocumentSummary, String>(
  (ref, documentId) => ref.watch(documentRepositoryProvider).fetchDocument(documentId),
);

/// Loads independently of the document list, per §8.1's "Storage Usage
/// card loads independently, each with its own placeholder."
final storageUsageProvider = FutureProvider<StorageUsage>(
  (ref) => ref.watch(documentRepositoryProvider).fetchStorageUsage(),
);
