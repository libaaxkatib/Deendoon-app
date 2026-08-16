import 'customer.dart';

/// One page of `GET /customers`, mirroring the controller's pagination
/// envelope exactly (`current_page`, `per_page`, `total`, `last_page`).
class CustomerPage {
  final List<Customer> customers;
  final int currentPage;
  final int lastPage;
  final int total;

  const CustomerPage({
    required this.customers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory CustomerPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['customers'] as List<dynamic>;
    return CustomerPage(
      customers: items
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
