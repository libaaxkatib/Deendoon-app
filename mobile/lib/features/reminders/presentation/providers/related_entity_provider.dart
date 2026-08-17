import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../cases/data/collection_case_repository.dart';
import '../../../customers/data/customer_repository.dart';
import '../../../customers/domain/customer_phone_number.dart';
import '../../../debts/data/debt_repository.dart';

/// Best-effort display name for a Reminder's `related_entity_type`/
/// `related_entity_id` pair. This is a polymorphic-by-convention pair on
/// the backend (not a real Eloquent morphTo, and not validated with an
/// `exists:` rule) — `ReminderResource` never embeds the related entity's
/// display data, so the client resolves it. `resolved: false` covers one
/// real, honest case: a genuinely dangling reference (the id doesn't
/// exist, a 404).
///
/// Fix #23 — [phoneNumbers] is populated everywhere [phone] already is
/// (customer/debt/promise_to_pay); `collection_case` resolves neither
/// today, a pre-existing gap this fix doesn't expand.
class RelatedEntitySummary {
  final String name;
  final bool resolved;
  final String? phone;
  final String? address;
  final List<CustomerPhoneNumber> phoneNumbers;

  const RelatedEntitySummary({
    required this.name,
    required this.resolved,
    this.phone,
    this.address,
    this.phoneNumbers = const [],
  });
}

/// Keyed by `"type:id"` rather than the `Reminder` object itself, so
/// repeated lookups for the same related entity share one cache entry
/// regardless of which `Reminder` instance triggered them.
final relatedEntityProvider =
    FutureProvider.family<RelatedEntitySummary, String>((ref, key) async {
      final parts = key.split(':');
      final type = parts.first;
      final id = parts.sublist(1).join(':');

      try {
        switch (type) {
          case 'customer':
            final customer = await ref
                .watch(customerRepositoryProvider)
                .fetchCustomer(id);
            return RelatedEntitySummary(
              name: customer.name,
              resolved: true,
              phone: customer.phone,
              address: customer.address,
              phoneNumbers: customer.phoneNumbers,
            );
          case 'debt':
            final debt = await ref.watch(debtRepositoryProvider).fetchDebt(id);
            final customer = await ref
                .watch(customerRepositoryProvider)
                .fetchCustomer(debt.customerId);
            return RelatedEntitySummary(
              name: customer.name,
              resolved: true,
              phone: customer.phone,
              address: customer.address,
              phoneNumbers: customer.phoneNumbers,
            );
          case 'collection_case':
            final collectionCase = await ref
                .watch(collectionCaseRepositoryProvider)
                .fetchCase(id);
            return RelatedEntitySummary(
              name: collectionCase.customerName ?? 'Unknown customer',
              resolved: true,
            );
          case 'promise_to_pay':
            final promise = await ref
                .watch(debtRepositoryProvider)
                .fetchPromiseToPayById(id);
            final debt = await ref
                .watch(debtRepositoryProvider)
                .fetchDebt(promise.debtId);
            final customer = await ref
                .watch(customerRepositoryProvider)
                .fetchCustomer(debt.customerId);
            return RelatedEntitySummary(
              name: customer.name,
              resolved: true,
              phone: customer.phone,
              address: customer.address,
              phoneNumbers: customer.phoneNumbers,
            );
          default:
            return RelatedEntitySummary(name: type, resolved: false);
        }
      } on ApiException {
        return const RelatedEntitySummary(
          name: 'Not available',
          resolved: false,
        );
      }
    });
