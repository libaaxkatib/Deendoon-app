import 'collection_case.dart';

/// One page of `GET /collection-cases`, mirroring the controller's
/// pagination envelope exactly (`current_page`, `per_page`, `total`,
/// `last_page`) — same shape as `DebtPage`, keyed `collection_cases`
/// instead of `debts`.
class CollectionCasePage {
  final List<CollectionCase> cases;
  final int currentPage;
  final int lastPage;
  final int total;

  const CollectionCasePage({
    required this.cases,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory CollectionCasePage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['collection_cases'] as List<dynamic>;
    return CollectionCasePage(
      cases: items.map((e) => CollectionCase.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
