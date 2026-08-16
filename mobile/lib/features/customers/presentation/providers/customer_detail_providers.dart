import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/document_summary.dart';
import '../../../../core/models/payment.dart';
import '../../../cases/data/collection_case_repository.dart';
import '../../../cases/domain/collection_case.dart';
import '../../data/customer_repository.dart';
import '../../domain/customer.dart';

/// Independent, family-keyed providers per customer id — same
/// per-component loading/error isolation pattern as the Home Dashboard
/// (Sprint 10): a failure fetching payments doesn't blank out the
/// already-loaded customer profile, and vice versa.
final customerDetailProvider = FutureProvider.family<Customer, String>(
  (ref, customerId) =>
      ref.watch(customerRepositoryProvider).fetchCustomer(customerId),
);

final customerPaymentsProvider = FutureProvider.family<List<Payment>, String>(
  (ref, customerId) =>
      ref.watch(customerRepositoryProvider).fetchPayments(customerId),
);

final customerDocumentsProvider =
    FutureProvider.family<List<DocumentSummary>, String>(
      (ref, customerId) =>
          ref.watch(customerRepositoryProvider).fetchDocuments(customerId),
    );

final customerCasesProvider =
    FutureProvider.family<List<CollectionCase>, String>(
      (ref, customerId) => ref
          .watch(collectionCaseRepositoryProvider)
          .fetchCasesForCustomer(customerId),
    );
