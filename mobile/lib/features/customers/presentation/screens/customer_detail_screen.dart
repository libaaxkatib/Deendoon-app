import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/customer_actions.dart';
import '../providers/customer_detail_providers.dart';
import '../widgets/credit_limit_sheet.dart';
import '../widgets/customer_info_card.dart';
import '../widgets/customer_recent_payments.dart';

/// Customer Details — Customer Information, Contact Details, Outstanding
/// Balance, Credit Limit (inline-editable via the dedicated
/// `PATCH .../credit-limit` endpoint), Risk Level (all from
/// `GET /customers/{id}`) and Recent Payments (`GET /customers/{id}/payments`).
/// Edit and Archive are real actions in the AppBar; Documents opens the
/// customer-scoped Documents list (`GET /customers/{id}/documents`);
/// Generate Statement is a real generation trigger
/// (`POST /customers/{id}/statements`), distinct from the Debt Detail
/// screen's own per-debt Statement generation.
///
/// "Cases" stays a `showComingSoon` stub — `CollectionCaseController::index()`
/// only filters by `status`/`tab`, there is no `customer_id` filter, so
/// there is no real destination to wire without inventing a backend
/// capability that doesn't exist.
///
/// "Active Cases" and "Recent Follow-ups" are deliberately not rendered —
/// no backend endpoint returns collection cases or follow-up history
/// scoped to a customer (`CollectionCaseController::index()` only filters
/// by `status`/`tab`; `FollowUpHistoryController` is per-debt, not
/// per-customer). Per this project's "never use mock data" rule and the
/// precedent set for Business Health, these are hidden entirely rather
/// than shown with a placeholder — add them back once a real endpoint
/// exists.
class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  /// Archiving soft-deletes the customer, and the plain `show` route is not
  /// `->withTrashed()` — this screen would 404 on any subsequent read, so
  /// there is nowhere useful to stay after a successful archive; pop back
  /// to the Customer List instead (restoring it back is only possible from
  /// there, via the "Show Archived" filter — see `customer_list_screen.dart`).
  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Customer'),
        content: const Text('This customer will no longer appear in the default list. This can be undone later.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Archive')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(customerActionsProvider).archive(customerId);
      messenger.showSnackBar(const SnackBar(content: Text('Customer archived successfully')));
      router.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Bare confirm-and-submit generation, same pattern as the Debt Detail
  /// screen's own "Generate Statement" — no dialog, since generating an
  /// extra document is not destructive. The underlying
  /// action already invalidates `customerDocumentsProvider`, so the
  /// Documents screen picks up the new entry the next time it's opened.
  Future<void> _generateStatement(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(customerActionsProvider).generateStatement(customerId);
      messenger.showSnackBar(const SnackBar(content: Text('Statement generated successfully')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(customerAsync.valueOrNull?.name ?? 'Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer',
            onPressed: () => context.push('/customers/$customerId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archive Customer',
            onPressed: () => _archive(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerDetailProvider(customerId));
          ref.invalidate(customerPaymentsProvider(customerId));
          await ref.read(customerDetailProvider(customerId).future);
        },
        child: customerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: 'Could not load this customer.',
                onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
              ),
            ),
          ),
          data: (customer) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CustomerInfoCard(
                customer: customer,
                onEditCreditLimit: () => showCreditLimitSheet(context, customerId, customer.creditLimit),
              ),
              const SizedBox(height: 24),
              const Text('Recent Payments', style: AppTypography.heading),
              const SizedBox(height: 12),
              CustomerRecentPayments(customerId: customerId),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/customers/$customerId/debts'),
                child: const Text('View Debts'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => showComingSoon(context, 'Cases'),
                      child: const Text('Cases'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/customers/$customerId/documents'),
                      child: const Text('Documents'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _generateStatement(context, ref),
                child: const Text('Generate Statement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
