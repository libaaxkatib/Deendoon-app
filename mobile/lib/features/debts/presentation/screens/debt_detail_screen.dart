import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/unavailable_section.dart';
import '../../../customers/presentation/providers/customer_detail_providers.dart';
import '../../../customers/presentation/widgets/customer_info_card.dart';
import '../providers/debt_actions.dart';
import '../providers/debt_detail_providers.dart';
import '../widgets/debt_documents_section.dart';
import '../widgets/debt_payment_history.dart';
import '../widgets/debt_summary_card.dart';
import '../widgets/debt_timeline_section.dart';
import '../widgets/promise_to_pay_sheet.dart';
import '../widgets/record_payment_sheet.dart';

/// Debt Details — Customer Information (reused from the Customers module),
/// Debt Summary + Collection Status, Payment History, Follow-up Timeline,
/// Promise to Pay History, Related Documents, Related Case.
///
/// Two sections keep their structural slot but show an honest
/// "not available" note rather than being removed — per Sprint 12's
/// explicit instruction — because no backend endpoint exists to fetch
/// them scoped to a single debt:
/// - Promise to Pay History: only `POST /debts/{id}/promise-to-pay`
///   (create) exists; there is no GET to list past promises.
/// - Related Case: only `POST /debts/{id}/collection-cases` (escalate/
///   create) exists; there is no GET to fetch an existing case for a debt.
class DebtDetailScreen extends ConsumerWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtDetailProvider(debtId));

    return Scaffold(
      appBar: AppBar(
        title: Text(debtAsync.valueOrNull?.referenceNumber ?? 'Debt Details'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(debtDetailProvider(debtId));
          ref.invalidate(debtPaymentsProvider(debtId));
          ref.invalidate(debtDocumentsProvider(debtId));
          ref.invalidate(debtTimelineProvider(debtId));
          await ref.read(debtDetailProvider(debtId).future);
        },
        child: debtAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: 'Could not load this debt.',
                onRetry: () => ref.invalidate(debtDetailProvider(debtId)),
              ),
            ),
          ),
          data: (debt) {
            final customerAsync = ref.watch(customerDetailProvider(debt.customerId));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Customer Information', style: AppTypography.heading),
                const SizedBox(height: 12),
                customerAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => RetrySection(
                    message: 'Could not load the customer for this debt.',
                    onRetry: () => ref.invalidate(customerDetailProvider(debt.customerId)),
                  ),
                  data: (customer) => CustomerInfoCard(customer: customer),
                ),
                const SizedBox(height: 24),
                const Text('Debt Summary', style: AppTypography.heading),
                const SizedBox(height: 12),
                DebtSummaryCard(debt: debt),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => showRecordPaymentSheet(context, debtId),
                        child: const Text('Record Payment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => showPromiseToPaySheet(context, debtId),
                        child: const Text('Promise to Pay'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref.read(debtActionsProvider).openCase(debtId);
                      messenger.showSnackBar(const SnackBar(content: Text('Case opened successfully')));
                    } catch (_) {
                      messenger.showSnackBar(const SnackBar(content: Text('Could not open a case for this debt')));
                    }
                  },
                  child: const Text('Open Case'),
                ),
                const SizedBox(height: 24),
                const Text('Payment History', style: AppTypography.heading),
                const SizedBox(height: 12),
                DebtPaymentHistory(debtId: debtId),
                const SizedBox(height: 24),
                const Text('Follow-up Timeline', style: AppTypography.heading),
                const SizedBox(height: 12),
                DebtTimelineSection(debtId: debtId),
                const SizedBox(height: 24),
                const Text('Promise to Pay History', style: AppTypography.heading),
                const SizedBox(height: 12),
                const UnavailableSection(
                  reason: 'Not available yet — the backend has no endpoint to list past '
                      'promises for a debt (only creating a new one is supported).',
                ),
                const SizedBox(height: 24),
                const Text('Related Documents', style: AppTypography.heading),
                const SizedBox(height: 12),
                DebtDocumentsSection(debtId: debtId),
                const SizedBox(height: 24),
                const Text('Related Case', style: AppTypography.heading),
                const SizedBox(height: 12),
                const UnavailableSection(
                  reason: 'Not available yet — the backend has no endpoint to fetch an '
                      'existing case for a debt (only opening a new one is supported).',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
