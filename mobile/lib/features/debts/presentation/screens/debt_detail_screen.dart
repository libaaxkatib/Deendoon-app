import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attachments/data/attachment_repository.dart';
import '../../../attachments/presentation/providers/attachment_providers.dart';
import '../../../customers/presentation/providers/customer_detail_providers.dart';
import '../../../customers/presentation/widgets/customer_info_card.dart';
import '../../../reminders/domain/reminder_entity_preset.dart';
import '../providers/debt_actions.dart';
import '../providers/debt_detail_providers.dart';
import '../widgets/debt_documents_section.dart';
import '../widgets/debt_payment_history.dart';
import '../widgets/debt_summary_card.dart';
import '../widgets/debt_timeline_section.dart';
import '../widgets/log_reminder_sheet.dart';
import '../widgets/open_case_button.dart';
import '../widgets/promise_to_pay_history_section.dart';
import '../widgets/promise_to_pay_sheet.dart';
import '../widgets/record_payment_sheet.dart';
import '../widgets/related_case_section.dart';

/// Debt Details — Customer Information (reused from the Customers module),
/// Debt Summary + Collection Status, Log Reminder (FR-030 Manual Reminder —
/// WhatsApp/SMS/Call, feeds the Follow-up Timeline below and may advance
/// Recovery Stage per BRL-031), Payment History, Follow-up Timeline,
/// Promise to Pay History, Generate Statement (the one document-generation
/// trigger in Sprint 19's agreed scope), Related Documents, Related Case.
/// Receipt generation has no separate trigger here — it's already an
/// automatic side effect of Record Payment (`PaymentService::record()` ->
/// `DocumentService::generateReceipt()`), wired since Sprint 12. Invoice
/// and Demand Letter generation are real, backend-supported endpoints too,
/// but were explicitly descoped from Sprint 19 (Product Owner decision) —
/// scheduled for the later module where document-generation workflows are
/// intentionally implemented (Professional Collection / Reports).
///
/// Promise to Pay History (`GET /debts/{id}/promise-to-pay`,
/// `PromiseToPayController::index`) and Related Case
/// (`GET /debts/{id}/collection-case`, `CollectionCaseController::forDebt`)
/// are both real, backend-supported sections (mobile Items 11/12).
class DebtDetailScreen extends ConsumerWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  /// Archiving soft-deletes the debt — same confirm-dialog pattern as
  /// `CustomerDetailScreen._archive`. There is nowhere useful to stay
  /// after a successful archive (every other section here assumes an
  /// active debt), so this pops back to the Debt List — restoring it is
  /// only possible from there, via the "Show Archived" filter.
  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    String customerId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.debtArchiveTitle),
        content: Text(l10n.debtArchiveDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.debtArchiveConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref
          .read(debtActionsProvider)
          .archive(debtId: debtId, customerId: customerId);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.debtArchivedSuccessfully)),
      );
      router.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Bare confirm-and-submit generation (Statement) — same pattern as
  /// "Open Case": no dialog, since generating an extra document is not a
  /// destructive action. Success/failure both surface as a snackbar; the
  /// underlying action already invalidates `debtDocumentsProvider`, so
  /// "Related Documents" below picks up the new entry automatically.
  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    String label,
    Future<void> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.debtDetailGenerateSuccessMessage(label))),
      );
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.debtDetailGenerateErrorMessage(label))),
      );
    }
  }

  /// Scan Invoice (P2.6) / Upload Invoice (P2.7). V1 scope only: capture or
  /// pick a file -> upload as a plain Debt Attachment (the same real,
  /// backend-supported `POST /debts/{id}/attachments` endpoint P1.6 built)
  /// — no OCR, no invoice-data extraction, no manual invoice metadata
  /// form. Tagged with `description: 'Invoice'` purely as a client-side
  /// label so it reads clearly in the Attachments list; the backend has no
  /// dedicated invoice-attachment type to set.
  Future<void> _attachInvoice(
    BuildContext context,
    WidgetRef ref,
    Future<PickedAttachmentFile?> Function() pick,
  ) async {
    final file = await pick();
    if (file == null || !context.mounted) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(attachmentRepositoryProvider)
          .uploadAttachment(
            entityPathPrefix: 'debts/$debtId',
            filePath: file.path,
            fileName: file.name,
            description: 'Invoice',
          );
      ref.invalidate(attachmentsProvider('debts/$debtId'));
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.debtDetailInvoiceAttachedSuccess)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final debtAsync = ref.watch(debtDetailProvider(debtId));
    final debtValue = debtAsync.valueOrNull;
    final isArchived = debtValue?.isArchived ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(debtValue?.referenceNumber ?? l10n.debtDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.addEditDebtEditTitle,
            onPressed: () => context.push('/debts/$debtId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: l10n.debtArchiveTitle,
            onPressed: debtValue == null || isArchived
                ? null
                : () => _archive(context, ref, debtValue.customerId),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(debtDetailProvider(debtId));
          ref.invalidate(debtPaymentsProvider(debtId));
          ref.invalidate(debtDocumentsProvider(debtId));
          ref.invalidate(debtTimelineProvider(debtId));
          ref.invalidate(debtPromiseToPayHistoryProvider(debtId));
          ref.invalidate(debtRelatedCaseProvider(debtId));
          await ref.read(debtDetailProvider(debtId).future);
        },
        child: debtAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RetrySection(
                message: l10n.debtDetailLoadError,
                onRetry: () => ref.invalidate(debtDetailProvider(debtId)),
              ),
            ),
          ),
          data: (debt) {
            final customerAsync = ref.watch(
              customerDetailProvider(debt.customerId),
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.debtDetailCustomerInfoHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                customerAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => RetrySection(
                    message: l10n.debtDetailCustomerLoadError,
                    onRetry: () =>
                        ref.invalidate(customerDetailProvider(debt.customerId)),
                  ),
                  data: (customer) => CustomerInfoCard(customer: customer),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailSummaryHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                DebtSummaryCard(debt: debt),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => showRecordPaymentSheet(
                          context,
                          debtId,
                          debt.customerId,
                        ),
                        child: Text(l10n.quickActionRecordPayment),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => showPromiseToPaySheet(context, debtId),
                        child: Text(l10n.promiseToPayTitle),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OpenCaseButton(debtId: debtId, customerId: debt.customerId),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailLogReminderHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            showLogReminderSheet(context, debtId, 'whatsapp'),
                        child: Text(l10n.debtDetailLogWhatsAppButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            showLogReminderSheet(context, debtId, 'sms'),
                        child: Text(l10n.debtDetailLogSmsButton),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () =>
                      showLogReminderSheet(context, debtId, 'call'),
                  child: Text(l10n.debtDetailLogCallButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: customerAsync.valueOrNull?.isReadOnly ?? false
                      ? null
                      : () => context.push(
                          '/reminders/new',
                          extra: ReminderEntityPreset(
                            type: 'debt',
                            id: debtId,
                            label: l10n.debtDetailReminderPresetLabel(
                              debt.referenceNumber,
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.add_alarm_outlined),
                  label: Text(l10n.quickActionAddReminder),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailPaymentHistoryHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                DebtPaymentHistory(debtId: debtId),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailFollowUpTimelineHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                DebtTimelineSection(debtId: debtId),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailPromiseToPayHistoryHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                PromiseToPayHistorySection(debtId: debtId),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailGenerateDocumentsHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _generate(
                    context,
                    ref,
                    l10n.documentTypeStatement,
                    () =>
                        ref.read(debtActionsProvider).generateStatement(debtId),
                  ),
                  child: Text(l10n.customerDetailGenerateStatementButton),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailRelatedDocumentsHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                DebtDocumentsSection(debtId: debtId),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => context.push('/debts/$debtId/attachments'),
                  child: Text(l10n.customerDetailAttachmentsButton),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _attachInvoice(
                          context,
                          ref,
                          ref.read(attachmentCameraProvider),
                        ),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(l10n.debtScanInvoiceButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _attachInvoice(
                          context,
                          ref,
                          ref.read(attachmentFilePickerProvider),
                        ),
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(l10n.debtUploadInvoiceButton),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.debtDetailRelatedCaseHeading,
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 12),
                RelatedCaseSection(debtId: debtId),
              ],
            );
          },
        ),
      ),
    );
  }
}
