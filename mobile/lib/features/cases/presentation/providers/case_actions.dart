import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_case_repository.dart';
import 'case_detail_providers.dart';

final caseActionsProvider = Provider<CaseActions>((ref) => CaseActions(ref));

/// The real, backend-supported Collection Case actions: recording an
/// activity (backs Add Follow-up/Mark Contacted/Record Visit — all three
/// are the same real endpoint, see `record_activity_sheet.dart`), closing
/// a case, and updating the case's Notes (`PUT /collection-cases/{id}`,
/// `UpdateCollectionCaseRequest` — the only editable field). Promise to
/// Pay is deliberately not duplicated here — it's the exact same
/// debt-level `POST /debts/{id}/promise-to-pay` already built in Sprint 12
/// (`debtActionsProvider.promiseToPay`), called with the case's `debtId`.
/// Escalate is not a per-case action: a Collection Case only exists
/// because a debt was already escalated, and there is no "escalate a case
/// further" endpoint. Collection Officer assignment (FR-041) was retired
/// in the RBAC Architecture Amendment — no assignment endpoint exists.
class CaseActions {
  final Ref _ref;

  const CaseActions(this._ref);

  CollectionCaseRepository get _repository => _ref.read(collectionCaseRepositoryProvider);

  Future<void> recordActivity({required String caseId, String? details}) async {
    await _repository.recordActivity(caseId: caseId, details: details);
    _ref.invalidate(caseDetailProvider(caseId));
    _ref.invalidate(caseHistoryProvider(caseId));
  }

  Future<void> close({required String caseId, required String closureOutcome}) async {
    await _repository.close(caseId: caseId, closureOutcome: closureOutcome);
    _ref.invalidate(caseDetailProvider(caseId));
    _ref.invalidate(caseHistoryProvider(caseId));
  }

  Future<void> updateNotes({required String caseId, String? notes}) async {
    await _repository.updateNotes(caseId: caseId, notes: notes);
    _ref.invalidate(caseDetailProvider(caseId));
  }
}
