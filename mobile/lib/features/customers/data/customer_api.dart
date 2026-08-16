import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/network/dio_client.dart';
import '../domain/customer.dart';
import '../domain/customer_page.dart';
import '../domain/customer_save_result.dart';
import '../domain/duplicate_warning.dart';
import '../../../core/models/payment.dart';

final customerApiProvider = Provider<CustomerApi>(
  (ref) => CustomerApi(ref.read(dioProvider)),
);

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
    bool includeArchived = false,
  }) async {
    final response = await _dio.get(
      'customers',
      queryParameters: {
        'page': page,
        'perPage': perPage,
        if (search.isNotEmpty) 'search': search,
        'status': ?status,
        'riskLevel': ?riskLevel,
        if (includeArchived) 'includeArchived': true,
      },
    );
    return CustomerPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Customer> show(String id) async {
    final response = await _dio.get('customers/$id');
    return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<Payment>> payments(String customerId) async {
    final response = await _dio.get('customers/$customerId/payments');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /customers/{id}/documents` (`DocumentController::forCustomer`) —
  /// same `DocumentSummary` shape as every other document listing, but a
  /// flat, unpaginated array (the controller combines and sorts, no
  /// pagination envelope), so no page/perPage params here.
  Future<List<DocumentSummary>> documents(String customerId) async {
    final response = await _dio.get('customers/$customerId/documents');
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((e) => DocumentSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  CustomerSaveResult _saveResultFrom(Map<String, dynamic> data) => (
    customer: Customer.fromJson(data['customer'] as Map<String, dynamic>),
    warning: data['warning'] != null
        ? DuplicateWarning.fromJson(data['warning'] as Map<String, dynamic>)
        : null,
  );

  Future<CustomerSaveResult> store({
    required String name,
    required String phone,
    String? address,
    required String creditLimit,
  }) async {
    final response = await _dio.post(
      'customers',
      data: {
        'name': name,
        'phone': phone,
        'address': address,
        'credit_limit': creditLimit,
      },
    );
    return _saveResultFrom(response.data['data'] as Map<String, dynamic>);
  }

  Future<CustomerSaveResult> update({
    required String id,
    required String name,
    required String phone,
    String? address,
    required String creditLimit,
  }) async {
    final response = await _dio.put(
      'customers/$id',
      data: {
        'name': name,
        'phone': phone,
        'address': address,
        'credit_limit': creditLimit,
      },
    );
    return _saveResultFrom(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> archive(String id) async {
    await _dio.post('customers/$id/archive');
  }

  /// `->withTrashed()` on the backend route — the only Customer route
  /// reachable for an already-archived (soft-deleted) id.
  Future<Customer> restore(String id) async {
    final response = await _dio.post('customers/$id/restore');
    return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Customer> updateCreditLimit({
    required String id,
    required String creditLimit,
  }) async {
    final response = await _dio.patch(
      'customers/$id/credit-limit',
      data: {'credit_limit': creditLimit},
    );
    return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `UpdateCustomerStatusRequest`: `customer_status` required, one of the
  /// real 7-value CHECK constraint set — same as `CustomerPolicy::update`
  /// (blocked when the customer is already read-only).
  Future<Customer> updateStatus({
    required String id,
    required String customerStatus,
  }) async {
    final response = await _dio.patch(
      'customers/$id/status',
      data: {'customer_status': customerStatus},
    );
    return Customer.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `POST /customers/{id}/statements` (`GenerateStatementRequest` — bare,
  /// no fields) — the per-customer Statement of Account, distinct from
  /// `DebtApi.generateStatement`'s per-debt equivalent.
  Future<DocumentSummary> generateStatement(String customerId) async {
    final response = await _dio.post('customers/$customerId/statements');
    return DocumentSummary.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// `POST /customers/check-duplicate` — standalone pre-submit check, used
  /// only from the Add Customer form. Unlike `store`/`update`, this never
  /// excludes an existing customer id server-side, so it must never be
  /// called from Edit Customer with unchanged name/phone (it would flag
  /// the customer's own record as a match of itself).
  Future<DuplicateWarning?> checkDuplicate({
    required String name,
    required String phone,
  }) async {
    final response = await _dio.post(
      'customers/check-duplicate',
      data: {'name': name, 'phone': phone},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return data['warning'] != null
        ? DuplicateWarning.fromJson(data['warning'] as Map<String, dynamic>)
        : null;
  }
}
