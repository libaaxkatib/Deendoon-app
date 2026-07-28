import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/coming_soon.dart';
import '../../../../core/widgets/retry_section.dart';
import '../providers/customer_detail_providers.dart';
import '../widgets/customer_info_card.dart';
import '../widgets/customer_recent_payments.dart';

/// Customer Details — Customer Information, Contact Details, Outstanding
/// Balance, Credit Limit, Risk Level (all from `GET /customers/{id}`) and
/// Recent Payments (`GET /customers/{id}/payments`).
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(customerAsync.valueOrNull?.name ?? 'Customer Details'),
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
              CustomerInfoCard(customer: customer),
              const SizedBox(height: 24),
              const Text('Recent Payments', style: AppTypography.heading),
              const SizedBox(height: 12),
              CustomerRecentPayments(customerId: customerId),
              const SizedBox(height: 24),
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
                      onPressed: () => showComingSoon(context, 'Documents'),
                      child: const Text('Documents'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
