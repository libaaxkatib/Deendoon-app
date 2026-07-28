import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/customer_repository.dart';
import '../../domain/customer.dart';
import '../../domain/customer_payment.dart';

/// Two independent, family-keyed providers per customer id — same
/// per-component loading/error isolation pattern as the Home Dashboard
/// (Sprint 10): a failure fetching payments doesn't blank out the
/// already-loaded customer profile, and vice versa.
final customerDetailProvider = FutureProvider.family<Customer, String>(
  (ref, customerId) => ref.watch(customerRepositoryProvider).fetchCustomer(customerId),
);

final customerPaymentsProvider = FutureProvider.family<List<CustomerPayment>, String>(
  (ref, customerId) => ref.watch(customerRepositoryProvider).fetchCustomerPayments(customerId),
);
