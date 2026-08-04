import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/professional_collection_repository.dart';
import '../../domain/professional_collection_request.dart';
import '../../domain/request_message.dart';

/// Independent, family-keyed providers per request id — same
/// per-component loading/error isolation pattern used across the app: a
/// failure fetching messages doesn't blank out an already-loaded request
/// summary, and vice versa.
final professionalCollectionDetailProvider = FutureProvider.family<ProfessionalCollectionRequest, String>(
  (ref, id) => ref.watch(professionalCollectionRepositoryProvider).fetchRequest(id),
);

final professionalCollectionMessagesProvider = FutureProvider.family<List<RequestMessage>, String>(
  (ref, id) => ref.watch(professionalCollectionRepositoryProvider).fetchMessages(id),
);
