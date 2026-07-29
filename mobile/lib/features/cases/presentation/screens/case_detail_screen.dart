import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../core/widgets/unavailable_section.dart';
import '../../../customers/presentation/providers/customer_detail_providers.dart';
import '../../../customers/presentation/widgets/customer_info_card.dart';
import '../../../debts/presentation/providers/debt_detail_providers.dart';
import '../../../debts/presentation/widgets/debt_documents_section.dart';
import '../../../debts/presentation/widgets/debt_payment_history.dart';
import '../../../debts/presentation/widgets/debt_summary_card.dart';
import '../../../debts/presentation/widgets/promise_to_pay_sheet.dart';
import '../providers/case_detail_providers.dart';
import '../widgets/case_summary_card.dart';
import '../widgets/case_timeline_section.dart';
import '../widgets/close_case_sheet.dart';
import '../widgets/collection_stage_card.dart';
import '../widgets/record_activity_sheet.dart';

/// Case Detail — Customer Summary and Debt Summary/Related
/// Documents/Related Payments are reused verbatim from the Customers
/// (Sprint 11) and Debts (Sprint 12) modules via the case's own
/// `customerId`/`debtId` — zero duplicated fetch logic. Collection Stage
/// reads `Debt.recoveryStage`. Timeline doubles as Follow-up History (one
/// real endpoint backs both, see `case_timeline_section.dart`). Notes has
/// no dedicated backend field/endpoint on a Collection Case — kept as an
/// honest `UnavailableSection` rather than removed, per this sprint's
/// explicit "keep the structure" instruction.
class CaseDetailScreen extends ConsumerWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseDetailProvider(caseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(caseAsync.valueOrNull?.referenceNumber ?? 'Case Details'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(caseDetailProvider(caseId));
          ref.invalidate(caseHistoryProvider(caseId));
          await ref.read(caseDetailProvider(caseId).future);
        },
        child: caseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: 'Could not load this case.',
                onRetry: () => ref.invalidate(caseDetailProvider(caseId)),
              ),
            ),
          ),
          data: (collectionCase) {
            final isOpen = collectionCase.caseStatus == 'open';
            final customerId = collectionCase.customerId;
            final debtAsync = ref.watch(debtDetailProvider(collectionCase.debtId));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Customer Summary', style: AppTypography.heading),
                const SizedBox(height: 12),
                if (customerId == null)
                  const UnavailableSection(reason: 'This case has no associated customer to display.')
                else
                  Consumer(
                    builder: (context, ref, _) {
                      final customerAsync = ref.watch(customerDetailProvider(customerId));
                      return customerAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => RetrySection(
                          message: 'Could not load the customer for this case.',
                          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
                        ),
                        data: (customer) => CustomerInfoCard(customer: customer),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                const Text('Debt Summary', style: AppTypography.heading),
                const SizedBox(height: 12),
                debtAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => RetrySection(
                    message: 'Could not load the debt for this case.',
                    onRetry: () => ref.invalidate(debtDetailProvider(collectionCase.debtId)),
                  ),
                  data: (debt) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DebtSummaryCard(debt: debt),
                      const SizedBox(height: 12),
                      CollectionStageCard(recoveryStage: debt.recoveryStage),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Case Summary', style: AppTypography.heading),
                const SizedBox(height: 12),
                CaseSummaryCard(collectionCase: collectionCase),
                const SizedBox(height: 24),
                if (isOpen) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showRecordActivitySheet(context, caseId, title: 'Add Follow-up'),
                          child: const Text('Add Follow-up'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showRecordActivitySheet(
                            context,
                            caseId,
                            title: 'Mark Contacted',
                            label: 'Contacted',
                          ),
                          child: const Text('Mark Contacted'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showRecordActivitySheet(
                            context,
                            caseId,
                            title: 'Record Visit',
                            label: 'Visit',
                          ),
                          child: const Text('Record Visit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showPromiseToPaySheet(context, collectionCase.debtId),
                          child: const Text('Promise to Pay'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => showCloseCaseSheet(context, caseId),
                    child: const Text('Close Case'),
                  ),
                ] else ...[
                  const UnavailableSection(
                    reason: 'This case is closed — no further activity, follow-up, or closure actions apply.',
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Timeline', style: AppTypography.heading),
                const SizedBox(height: 12),
                CaseTimelineSection(caseId: caseId),
                const SizedBox(height: 24),
                const Text('Notes', style: AppTypography.heading),
                const SizedBox(height: 12),
                const UnavailableSection(
                  reason: 'Not available yet — a Collection Case has no dedicated Notes field or endpoint. '
                      'Free-text details from individual activities are visible in the Timeline above.',
                ),
                const SizedBox(height: 24),
                const Text('Related Documents', style: AppTypography.heading),
                const SizedBox(height: 12),
                DebtDocumentsSection(debtId: collectionCase.debtId),
                const SizedBox(height: 24),
                const Text('Related Payments', style: AppTypography.heading),
                const SizedBox(height: 12),
                DebtPaymentHistory(debtId: collectionCase.debtId),
              ],
            );
          },
        ),
      ),
    );
  }
}
