import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../domain/customer.dart';
import '../domain/customer_page.dart';
import '../domain/customer_payment.dart';
import 'customer_api.dart';

final customerRepositoryProvider =
    Provider<CustomerRepository>((ref) => CustomerRepository(ref.read(customerApiProvider)));

/// Translates raw Dio failures into `ApiException` — same pattern as
/// `AuthRepository`/`DashboardRepository`. No caching, no calculation:
/// each method is a direct pass-through to the matching `CustomerApi` call.
class CustomerRepository {
  final CustomerApi _api;

  const CustomerRepository(this._api);

  Future<CustomerPage> fetchCustomers({
    required int page,
    String search = '',
    String? status,
    String? riskLevel,
  }) =>
      _guard(() => _api.list(page: page, search: search, status: status, riskLevel: riskLevel));

  Future<Customer> fetchCustomer(String id) => _guard(() => _api.show(id));

  Future<List<CustomerPayment>> fetchCustomerPayments(String customerId) =>
      _guard(() => _api.payments(customerId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
