import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/document_summary.dart';
import '../../../core/network/api_exception.dart';
import '../domain/customer.dart';
import '../domain/customer_page.dart';
import '../domain/customer_phone_number.dart';
import '../domain/customer_save_result.dart';
import '../domain/duplicate_warning.dart';
import '../../../core/models/payment.dart';
import 'customer_api.dart';

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.read(customerApiProvider)),
);

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
    bool includeArchived = false,
  }) => _guard(
    () => _api.list(
      page: page,
      search: search,
      status: status,
      riskLevel: riskLevel,
      includeArchived: includeArchived,
    ),
  );

  Future<Customer> fetchCustomer(String id) => _guard(() => _api.show(id));

  Future<List<Payment>> fetchPayments(String customerId) =>
      _guard(() => _api.payments(customerId));

  Future<List<DocumentSummary>> fetchDocuments(String customerId) =>
      _guard(() => _api.documents(customerId));

  Future<CustomerSaveResult> createCustomer({
    required String name,
    required String phone,
    String? address,
    required String creditLimit,
    List<CustomerPhoneNumber>? phoneNumbers,
  }) => _guard(
    () => _api.store(
      name: name,
      phone: phone,
      address: address,
      creditLimit: creditLimit,
      phoneNumbers: phoneNumbers,
    ),
  );

  Future<CustomerSaveResult> updateCustomer({
    required String id,
    required String name,
    required String phone,
    String? address,
    required String creditLimit,
    List<CustomerPhoneNumber>? phoneNumbers,
  }) => _guard(
    () => _api.update(
      id: id,
      name: name,
      phone: phone,
      address: address,
      creditLimit: creditLimit,
      phoneNumbers: phoneNumbers,
    ),
  );

  Future<void> archiveCustomer(String id) => _guard(() => _api.archive(id));

  Future<Customer> restoreCustomer(String id) => _guard(() => _api.restore(id));

  Future<Customer> updateCreditLimit({
    required String id,
    required String creditLimit,
  }) => _guard(() => _api.updateCreditLimit(id: id, creditLimit: creditLimit));

  Future<Customer> updateStatus({
    required String id,
    required String customerStatus,
  }) => _guard(() => _api.updateStatus(id: id, customerStatus: customerStatus));

  Future<DuplicateWarning?> checkDuplicateCustomer({
    required String name,
    required String phone,
  }) => _guard(() => _api.checkDuplicate(name: name, phone: phone));

  Future<DocumentSummary> generateStatement(String customerId) =>
      _guard(() => _api.generateStatement(customerId));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
