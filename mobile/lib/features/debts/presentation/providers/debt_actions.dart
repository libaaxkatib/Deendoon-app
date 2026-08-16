import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/document_summary.dart';
import '../../../cases/domain/collection_case.dart';
import '../../../cases/presentation/providers/case_list_provider.dart';
import '../../../customers/presentation/providers/customer_detail_providers.dart';
import '../../data/debt_repository.dart';
import '../../domain/debt_save_result.dart';
import 'debt_detail_providers.dart';
import 'debt_list_provider.dart';

final debtActionsProvider = Provider<DebtActions>((ref) => DebtActions(ref));

/// The real, backend-supported Debt actions (Add Debt, Edit Debt, Record
/// Payment, Promise to Pay, Open Case). Each is a direct call to the real
/// endpoint; on success, the affected detail/list providers are invalidated
/// so the screen reflects the real, updated state — never an
/// optimistic/local mutation.
class DebtActions {
  final Ref _ref;

  const DebtActions(this._ref);

  DebtRepository get _repository => _ref.read(debtRepositoryProvider);

  Future<DebtSaveResult> create({
    required String customerId,
    required String amount,
    required String dueDate,
    String? notes,
  }) async {
    final result = await _repository.createDebt(
      customerId: customerId,
      amount: amount,
      dueDate: dueDate,
      notes: notes,
    );
    _ref.invalidate(debtListProvider(customerId));
    return result;
  }

  Future<void> update({
    required String debtId,
    required String dueDate,
    String? notes,
  }) async {
    final debt = await _repository.updateDebt(
      debtId: debtId,
      dueDate: dueDate,
      notes: notes,
    );
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtListProvider(debt.customerId));
  }

  /// Mobile Fix #13: `PaymentService::record()` also recalculates the
  /// Customer's balances/risk level/credit score (always) and may fulfill
  /// a Promise to Pay or generate a Receipt Document — `customerId` is
  /// required so every one of those sibling providers can be invalidated
  /// alongside the debt-scoped ones, not just the screen the payment was
  /// recorded from.
  Future<void> recordPayment({
    required String debtId,
    required String customerId,
    required String amount,
    required String paymentDate,
    String? paymentMethod,
    String? referenceNotes,
  }) async {
    await _repository.recordPayment(
      debtId: debtId,
      amount: amount,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      referenceNotes: referenceNotes,
    );
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtPaymentsProvider(debtId));
    _ref.invalidate(debtTimelineProvider(debtId));
    _ref.invalidate(debtListProvider(customerId));
    _ref.invalidate(customerDetailProvider(customerId));
    _ref.invalidate(customerPaymentsProvider(customerId));
    _ref.invalidate(debtDocumentsProvider(debtId));
    _ref.invalidate(debtPromiseToPayHistoryProvider(debtId));
  }

  Future<void> promiseToPay({
    required String debtId,
    required String promisedDate,
  }) async {
    await _repository.promiseToPay(debtId: debtId, promisedDate: promisedDate);
    _ref.invalidate(debtTimelineProvider(debtId));
    _ref.invalidate(debtPromiseToPayHistoryProvider(debtId));
  }

  /// Mobile Fix #13: `CollectionCaseService::escalate()` also advances the
  /// Debt's own recovery stage and recalculates the Customer's risk
  /// level/credit score, and the new case belongs on both the Case List
  /// and the Customer's own Cases screen — `customerId` is required so
  /// all four can be invalidated alongside `debtRelatedCaseProvider`.
  Future<CollectionCase> openCase(String debtId, String customerId) async {
    final collectionCase = await _repository.openCase(debtId);
    _ref.invalidate(debtRelatedCaseProvider(debtId));
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(customerDetailProvider(customerId));
    _ref.invalidate(caseListProvider);
    _ref.invalidate(customerCasesProvider(customerId));
    return collectionCase;
  }

  Future<DocumentSummary> generateStatement(String debtId) async {
    final statement = await _repository.generateStatement(debtId);
    _ref.invalidate(debtDocumentsProvider(debtId));
    return statement;
  }

  /// Archiving soft-deletes the debt — mirrors `CustomerActions.archive`.
  /// Unlike Customer's `show` route, Debt's `show`/`restore` routes ARE
  /// `->withTrashed()`, but the mobile UX still treats an archived debt as
  /// list-only (same as Customer), so callers navigate away rather than
  /// re-render the same Detail screen.
  Future<void> archive({
    required String debtId,
    required String customerId,
  }) async {
    await _repository.archiveDebt(debtId);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtListProvider(customerId));
  }

  Future<void> restore({
    required String debtId,
    required String customerId,
  }) async {
    await _repository.restoreDebt(debtId);
    _ref.invalidate(debtListProvider(customerId));
  }

  /// FR-030 Manual Reminder logging — each call may also advance Recovery
  /// Stage (BRL-031) server-side, so the detail provider is invalidated
  /// alongside the timeline, not just the timeline on its own.
  Future<void> logWhatsAppReminder({
    required String debtId,
    String? details,
  }) async {
    await _repository.logWhatsAppReminder(debtId: debtId, details: details);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtTimelineProvider(debtId));
  }

  Future<void> logSmsReminder({required String debtId, String? details}) async {
    await _repository.logSmsReminder(debtId: debtId, details: details);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtTimelineProvider(debtId));
  }

  Future<void> logCallReminder({
    required String debtId,
    String? details,
  }) async {
    await _repository.logCallReminder(debtId: debtId, details: details);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtTimelineProvider(debtId));
  }
}
