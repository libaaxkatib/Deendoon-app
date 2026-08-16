import 'debt.dart';

/// One page of `GET /debts`, mirroring the controller's pagination
/// envelope exactly (`current_page`, `per_page`, `total`, `last_page`).
class DebtPage {
  final List<Debt> debts;
  final int currentPage;
  final int lastPage;
  final int total;

  const DebtPage({
    required this.debts,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory DebtPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['debts'] as List<dynamic>;
    return DebtPage(
      debts: items
          .map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
