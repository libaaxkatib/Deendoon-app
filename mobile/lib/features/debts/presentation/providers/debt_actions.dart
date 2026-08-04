import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/document_summary.dart';
import '../../../cases/domain/collection_case.dart';
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
    final result = await _repository.createDebt(customerId: customerId, amount: amount, dueDate: dueDate, notes: notes);
    _ref.invalidate(debtListProvider(customerId));
    return result;
  }

  Future<void> update({required String debtId, required String dueDate, String? notes}) async {
    final debt = await _repository.updateDebt(debtId: debtId, dueDate: dueDate, notes: notes);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtListProvider(debt.customerId));
  }

  Future<void> recordPayment({
    required String debtId,
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
  }

  Future<void> promiseToPay({required String debtId, required String promisedDate}) async {
    await _repository.promiseToPay(debtId: debtId, promisedDate: promisedDate);
    _ref.invalidate(debtTimelineProvider(debtId));
  }

  Future<CollectionCase> openCase(String debtId) => _repository.openCase(debtId);

  Future<DocumentSummary> generateStatement(String debtId) async {
    final statement = await _repository.generateStatement(debtId);
    _ref.invalidate(debtDocumentsProvider(debtId));
    return statement;
  }

  /// FR-030 Manual Reminder logging — each call may also advance Recovery
  /// Stage (BRL-031) server-side, so the detail provider is invalidated
  /// alongside the timeline, not just the timeline on its own.
  Future<void> logWhatsAppReminder({required String debtId, String? details}) async {
    await _repository.logWhatsAppReminder(debtId: debtId, details: details);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtTimelineProvider(debtId));
  }

  Future<void> logSmsReminder({required String debtId, String? details}) async {
    await _repository.logSmsReminder(debtId: debtId, details: details);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtTimelineProvider(debtId));
  }

  Future<void> logCallReminder({required String debtId, String? details}) async {
    await _repository.logCallReminder(debtId: debtId, details: details);
    _ref.invalidate(debtDetailProvider(debtId));
    _ref.invalidate(debtTimelineProvider(debtId));
  }
}
