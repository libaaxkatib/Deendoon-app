import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/debt_repository.dart';
import 'debt_detail_providers.dart';

final debtActionsProvider = Provider<DebtActions>((ref) => DebtActions(ref));

/// The three real, backend-supported Debt actions (Record Payment, Promise
/// to Pay, Open Case). Each is a direct call to the real endpoint; on
/// success, the affected detail providers are invalidated so the screen
/// reflects the real, updated state — never an optimistic/local mutation.
class DebtActions {
  final Ref _ref;

  const DebtActions(this._ref);

  DebtRepository get _repository => _ref.read(debtRepositoryProvider);

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

  Future<void> openCase(String debtId) async {
    await _repository.openCase(debtId);
  }
}
