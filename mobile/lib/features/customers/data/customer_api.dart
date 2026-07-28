import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/customer.dart';
import '../domain/customer_page.dart';
import '../domain/customer_payment.dart';

final customerApiProvider = Provider<CustomerApi>((ref) => CustomerApi(ref.read(dioProvider)));

/// Thin wrapper around `GET /customers*` — mirrors
/// `App\Http\Controllers\CustomerController` and
/// `App\Http\Controllers\PaymentController::forCustomer` exactly. Query
/// param names match the backend literally (camelCase — `riskLevel`,
/// not `risk_level` — this endpoint's filters are camelCase while every
/// JSON response body is snake_case; confirmed by reading the controller).
class CustomerApi {
  final Dio _dio;

  const CustomerApi(this._dio);

  Future<CustomerPage> list({
    required int page,
    int perPage = 20,
    String search = '',
    String? status,
    String? riskLevel,
  }) async {
    final response = await _dio.get('customers', queryParameters: {
      'page': page,
      'perPage': perPage,
      if (search.isNotEmpty) 'search': search,
      'status': ?status,
      'riskLevel': ?riskLevel,
    });
    return CustomerPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Customer> show(String id) async {
    final response = await _dio.get('customers/$id');
    return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<CustomerPayment>> payments(String customerId) async {
    final response = await _dio.get('customers/$customerId/payments');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => CustomerPayment.fromJson(e as Map<String, dynamic>)).toList();
  }
}
