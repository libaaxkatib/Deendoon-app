import '../../../core/models/document_summary.dart';
import '../../../core/models/payment.dart';
import '../../cases/domain/collection_case.dart';
import '../../customers/domain/customer.dart';
import '../../debts/domain/debt.dart';

/// Mirrors `SearchController::index()`'s exact response shape (FR-063,
/// `GET /search?q=...`). Each key is `null` when the acting user's role
/// cannot view that entity type at all (per-entity RBAC applied
/// server-side in `SearchService`), and an empty list when the role can
/// view it but nothing matched — these are different, both real, states,
/// not collapsed into one.
///
/// `receipts`/`demandLetters`/`statements` all share the exact
/// `DocumentSummary` shape already used by the Documents module, so no
/// new document model is introduced.
class SearchResults {
  final List<Customer>? customers;
  final List<Debt>? debts;
  final List<Payment>? payments;
  final List<DocumentSummary>? receipts;
  final List<DocumentSummary>? demandLetters;
  final List<DocumentSummary>? statements;
  final List<CollectionCase>? collectionCases;

  const SearchResults({
    required this.customers,
    required this.debts,
    required this.payments,
    required this.receipts,
    required this.demandLetters,
    required this.statements,
    required this.collectionCases,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    List<T>? parseList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final value = json[key];
      if (value is! List) return null;
      return value.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }

    return SearchResults(
      customers: parseList('customers', Customer.fromJson),
      debts: parseList('debts', Debt.fromJson),
      payments: parseList('payments', Payment.fromJson),
      receipts: parseList('receipts', DocumentSummary.fromJson),
      demandLetters: parseList('demand_letters', DocumentSummary.fromJson),
      statements: parseList('statements', DocumentSummary.fromJson),
      collectionCases: parseList('collection_cases', CollectionCase.fromJson),
    );
  }

  /// All three document types combined — the UI treats them as one
  /// "Documents" category, matching how the Documents module already
  /// presents receipts/demand letters/statements together.
  List<DocumentSummary> get documents => [
        ...?receipts,
        ...?demandLetters,
        ...?statements,
      ];

  int get totalCount =>
      (customers?.length ?? 0) +
      (debts?.length ?? 0) +
      (payments?.length ?? 0) +
      documents.length +
      (collectionCases?.length ?? 0);
}
