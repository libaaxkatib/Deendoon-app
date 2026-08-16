import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../debts/presentation/providers/debt_detail_providers.dart';
import '../../data/collection_case_repository.dart';
import 'case_detail_providers.dart';
import 'case_list_provider.dart';

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

  CollectionCaseRepository get _repository =>
      _ref.read(collectionCaseRepositoryProvider);

  /// Mobile Fix #13: the Case List shows this case's status/last-activity
  /// too, so it must be invalidated alongside the detail/history pair.
  Future<void> recordActivity({required String caseId, String? details}) async {
    await _repository.recordActivity(caseId: caseId, details: details);
    _ref.invalidate(caseDetailProvider(caseId));
    _ref.invalidate(caseHistoryProvider(caseId));
    _ref.invalidate(caseListProvider);
  }

  /// Mobile Fix #13: `debtId` is required so the Debt Detail screen's
  /// "Related Case" section (`debtRelatedCaseProvider`) — which shows this
  /// same case's status — doesn't keep showing it as open, alongside the
  /// Case List, which also needs to reflect the closure.
  Future<void> close({
    required String caseId,
    required String debtId,
    required String closureOutcome,
  }) async {
    await _repository.close(caseId: caseId, closureOutcome: closureOutcome);
    _ref.invalidate(caseDetailProvider(caseId));
    _ref.invalidate(caseHistoryProvider(caseId));
    _ref.invalidate(caseListProvider);
    _ref.invalidate(debtRelatedCaseProvider(debtId));
  }

  /// Mobile Fix #13: a notes edit writes an `AuditLog::Edited` entry, and
  /// `CollectionCaseController::history()` merges AuditLog entries into
  /// the same History the Timeline section renders — so `caseHistoryProvider`
  /// must be invalidated here too, not just `caseDetailProvider`.
  Future<void> updateNotes({required String caseId, String? notes}) async {
    await _repository.updateNotes(caseId: caseId, notes: notes);
    _ref.invalidate(caseDetailProvider(caseId));
    _ref.invalidate(caseHistoryProvider(caseId));
  }
}
