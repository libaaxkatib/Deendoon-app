import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/payment.dart';
import '../../../cases/domain/collection_case.dart';
import '../../data/debt_repository.dart';
import '../../domain/debt.dart';
import '../../../../core/models/document_summary.dart';
import '../../domain/debt_timeline.dart';
import '../../domain/promise_to_pay.dart';

/// Independent, family-keyed providers per debt id — same per-component
/// loading/error isolation pattern as the Home Dashboard and Customer
/// Details: a failure in one section never blanks out an already-loaded
/// sibling section.
final debtDetailProvider = FutureProvider.family<Debt, String>(
  (ref, debtId) => ref.watch(debtRepositoryProvider).fetchDebt(debtId),
);

final debtPaymentsProvider = FutureProvider.family<List<Payment>, String>(
  (ref, debtId) => ref.watch(debtRepositoryProvider).fetchPayments(debtId),
);

final debtDocumentsProvider =
    FutureProvider.family<List<DocumentSummary>, String>(
      (ref, debtId) => ref.watch(debtRepositoryProvider).fetchDocuments(debtId),
    );

final debtTimelineProvider = FutureProvider.family<DebtTimeline, String>(
  (ref, debtId) => ref.watch(debtRepositoryProvider).fetchTimeline(debtId),
);

final debtPromiseToPayHistoryProvider =
    FutureProvider.family<List<PromiseToPay>, String>(
      (ref, debtId) =>
          ref.watch(debtRepositoryProvider).fetchPromiseToPayHistory(debtId),
    );

/// Null is a real, expected value here — "no related case yet" — not a
/// loading/error state; see `DebtRepository.fetchRelatedCase()`.
final debtRelatedCaseProvider = FutureProvider.family<CollectionCase?, String>(
  (ref, debtId) => ref.watch(debtRepositoryProvider).fetchRelatedCase(debtId),
);
