import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../cases/data/collection_case_repository.dart';
import '../../../customers/data/customer_repository.dart';
import '../../../debts/data/debt_repository.dart';

/// Best-effort display name for a Reminder's `related_entity_type`/
/// `related_entity_id` pair. This is a polymorphic-by-convention pair on
/// the backend (not a real Eloquent morphTo, and not validated with an
/// `exists:` rule) — `ReminderResource` never embeds the related entity's
/// display data, so the client resolves it. `resolved: false` covers two
/// real, honest cases: `promise_to_pay` (no `GET` endpoint exists to
/// fetch an individual promise by id — see the Sprint 12/14 summaries),
/// and a genuinely dangling reference (the id doesn't exist, a 404).
class RelatedEntitySummary {
  final String name;
  final bool resolved;

  const RelatedEntitySummary({required this.name, required this.resolved});
}

/// Keyed by `"type:id"` rather than the `Reminder` object itself, so
/// repeated lookups for the same related entity share one cache entry
/// regardless of which `Reminder` instance triggered them.
final relatedEntityProvider = FutureProvider.family<RelatedEntitySummary, String>((ref, key) async {
  final parts = key.split(':');
  final type = parts.first;
  final id = parts.sublist(1).join(':');

  try {
    switch (type) {
      case 'customer':
        final customer = await ref.watch(customerRepositoryProvider).fetchCustomer(id);
        return RelatedEntitySummary(name: customer.name, resolved: true);
      case 'debt':
        final debt = await ref.watch(debtRepositoryProvider).fetchDebt(id);
        final customer = await ref.watch(customerRepositoryProvider).fetchCustomer(debt.customerId);
        return RelatedEntitySummary(name: customer.name, resolved: true);
      case 'collection_case':
        final collectionCase = await ref.watch(collectionCaseRepositoryProvider).fetchCase(id);
        return RelatedEntitySummary(name: collectionCase.customerName ?? 'Unknown customer', resolved: true);
      case 'promise_to_pay':
        return const RelatedEntitySummary(name: 'Promise to Pay', resolved: false);
      default:
        return RelatedEntitySummary(name: type, resolved: false);
    }
  } on ApiException {
    return const RelatedEntitySummary(name: 'Not available', resolved: false);
  }
});
