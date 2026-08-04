import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/professional_collection_repository.dart';
import '../../domain/professional_collection_request.dart';
import '../../domain/request_message.dart';
import 'professional_collection_detail_providers.dart';
import 'professional_collection_list_provider.dart';

final professionalCollectionActionsProvider =
    Provider<ProfessionalCollectionActions>((ref) => ProfessionalCollectionActions(ref));

/// The real, backend-supported Business Owner actions on Professional
/// Collection Requests: submit (from a Collection Case) and post a
/// message. `transitionStatus`/`close` are Deendoon-Platform-
/// Administrator-only (`ProfessionalCollectionRequestPolicy`) and are
/// deliberately not exposed here — Sprint 20 Unit 1 scope excludes them.
class ProfessionalCollectionActions {
  final Ref _ref;

  const ProfessionalCollectionActions(this._ref);

  ProfessionalCollectionRepository get _repository => _ref.read(professionalCollectionRepositoryProvider);

  Future<ProfessionalCollectionRequest> submit(String caseId) async {
    final request = await _repository.submit(caseId);
    _ref.invalidate(professionalCollectionListProvider);
    return request;
  }

  Future<RequestMessage> postMessage({required String requestId, required String content}) async {
    final message = await _repository.postMessage(id: requestId, content: content);
    _ref.invalidate(professionalCollectionMessagesProvider(requestId));
    return message;
  }
}
