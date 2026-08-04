import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/document_summary.dart';
import '../../data/customer_repository.dart';
import '../../domain/customer_save_result.dart';
import '../../domain/duplicate_warning.dart';
import 'customer_detail_providers.dart';
import 'customer_list_provider.dart';

final customerActionsProvider = Provider<CustomerActions>((ref) => CustomerActions(ref));

/// The real, backend-supported Customer mutations: create, update,
/// archive, restore, and the dedicated credit-limit endpoint — plus the
/// standalone duplicate pre-check. Every mutation invalidates
/// `customerListProvider` rather than patching it in place, matching
/// `ReminderActions`' create/update — simplicity over an in-place merge
/// that would need to reproduce the same search/includeArchived filters.
class CustomerActions {
  final Ref _ref;

  const CustomerActions(this._ref);

  CustomerRepository get _repository => _ref.read(customerRepositoryProvider);

  Future<CustomerSaveResult> create({
    required String name,
    required String phone,
    required String creditLimit,
  }) async {
    final result = await _repository.createCustomer(name: name, phone: phone, creditLimit: creditLimit);
    _ref.invalidate(customerListProvider);
    return result;
  }

  Future<CustomerSaveResult> update({
    required String id,
    required String name,
    required String phone,
    required String creditLimit,
  }) async {
    final result = await _repository.updateCustomer(id: id, name: name, phone: phone, creditLimit: creditLimit);
    _ref.invalidate(customerDetailProvider(id));
    _ref.invalidate(customerListProvider);
    return result;
  }

  /// Archiving soft-deletes the customer — the plain `show`/`update`
  /// routes are not `->withTrashed()`, so `customerDetailProvider(id)`
  /// would 404 on any subsequent read. Invalidating it here just clears
  /// the cached value; callers must navigate away rather than re-render
  /// the same Detail screen.
  Future<void> archive(String id) async {
    await _repository.archiveCustomer(id);
    _ref.invalidate(customerDetailProvider(id));
    _ref.invalidate(customerListProvider);
  }

  Future<void> restore(String id) async {
    await _repository.restoreCustomer(id);
    _ref.invalidate(customerListProvider);
  }

  Future<void> updateCreditLimit({required String id, required String creditLimit}) async {
    await _repository.updateCreditLimit(id: id, creditLimit: creditLimit);
    _ref.invalidate(customerDetailProvider(id));
    _ref.invalidate(customerListProvider);
  }

  Future<DuplicateWarning?> checkDuplicate({required String name, required String phone}) =>
      _repository.checkDuplicateCustomer(name: name, phone: phone);

  Future<DocumentSummary> generateStatement(String customerId) async {
    final statement = await _repository.generateStatement(customerId);
    _ref.invalidate(customerDocumentsProvider(customerId));
    return statement;
  }
}
