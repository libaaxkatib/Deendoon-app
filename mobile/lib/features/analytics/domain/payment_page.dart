import '../../../core/models/payment.dart';

/// One page of `GET /reports/payments`, mirroring the controller's
/// pagination envelope exactly (`current_page`, `per_page`, `total`,
/// `last_page`) — same shape as `CustomerPage`/`DebtPage`, keyed
/// `payments`. No equivalent existed before this sprint: the two other
/// places `Payment` is fetched (`GET /customers/{id}/payments`,
/// `GET /debts/{id}/payments`) both return a flat, unpaginated list.
class PaymentPage {
  final List<Payment> payments;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaymentPage({
    required this.payments,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaymentPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['payments'] as List<dynamic>;
    return PaymentPage(
      payments: items.map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
