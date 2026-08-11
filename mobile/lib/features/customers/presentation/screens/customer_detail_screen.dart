import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/retry_section.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../reminders/domain/reminder_entity_preset.dart';
import '../providers/customer_actions.dart';
import '../providers/customer_detail_providers.dart';
import '../widgets/credit_limit_sheet.dart';
import '../widgets/customer_info_card.dart';
import '../widgets/customer_status_sheet.dart';
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
/// "Cases" opens `CustomerCasesScreen`, backed by
/// `CollectionCaseController::index()`'s `customer_id` filter (added
/// alongside this screen).
///
/// "Active Cases" and "Recent Follow-ups" are deliberately not rendered —
/// no backend endpoint returns follow-up history scoped to a customer
/// (`FollowUpHistoryController` is per-debt, not per-customer; "Active
/// Cases" is now covered by the real "Cases" destination above). Per this
/// project's "never use mock data" rule and the precedent set for Business
/// Health, "Recent Follow-ups" stays hidden entirely rather than shown
/// with a placeholder — add it back once a real per-customer endpoint
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customerArchiveTitle),
        content: Text(l10n.customerArchiveDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.customerArchiveConfirmButton)),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref.read(customerActionsProvider).archive(customerId);
      messenger.showSnackBar(SnackBar(content: Text(l10n.customerArchivedSuccessfully)));
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
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(customerActionsProvider).generateStatement(customerId);
      messenger.showSnackBar(SnackBar(content: Text(l10n.customerStatementGeneratedSuccessfully)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    final customer = customerAsync.valueOrNull;
    final isReadOnly = customer?.isReadOnly ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer?.name ?? l10n.customerDetailsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: isReadOnly ? l10n.customerReadOnlyTooltip : l10n.customerEditTitle,
            onPressed: customer == null || isReadOnly ? null : () => context.push('/customers/$customerId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: isReadOnly ? l10n.customerReadOnlyTooltip : l10n.customerArchiveTitle,
            onPressed: customer == null || isReadOnly ? null : () => _archive(context, ref),
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
                message: l10n.customerDetailLoadError,
                onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
              ),
            ),
          ),
          data: (customer) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CustomerInfoCard(
                customer: customer,
                onEditCreditLimit: customer.isReadOnly
                    ? null
                    : () => showCreditLimitSheet(context, customerId, customer.creditLimit),
                onEditStatus: customer.isReadOnly
                    ? null
                    : () => showCustomerStatusSheet(context, customerId, customer.customerStatus),
              ),
              if (customer.isReadOnly) ...[
                const SizedBox(height: 16),
                const _CustomerReadOnlyBanner(),
              ],
              const SizedBox(height: 24),
              Text(l10n.customerDetailRecentPaymentsHeading, style: AppTypography.heading),
              const SizedBox(height: 12),
              CustomerRecentPayments(customerId: customerId),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/customers/$customerId/debts'),
                child: Text(l10n.customerDetailViewDebtsButton),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/customers/$customerId/cases'),
                      child: Text(l10n.navCases),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/customers/$customerId/documents'),
                      child: Text(l10n.navDocuments),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/customers/$customerId/attachments', extra: !customer.isReadOnly),
                child: Text(l10n.customerDetailAttachmentsButton),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: customer.isReadOnly ? null : () => _generateStatement(context, ref),
                child: Text(l10n.customerDetailGenerateStatementButton),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: customer.isReadOnly
                    ? null
                    : () => context.push(
                          '/reminders/new',
                          extra: ReminderEntityPreset(type: 'customer', id: customerId, label: customer.name),
                        ),
                icon: const Icon(Icons.add_alarm_outlined),
                label: Text(l10n.quickActionAddReminder),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FR-083: a read-only Customer remains fully viewable and searchable but
/// cannot be edited, archived, or have documents generated against it
/// until the tenant is back under its plan's effective customer limit.
/// Same visual language as Subscription's `_ReadOnlyBanner`, scoped to
/// this one customer rather than the whole tenant.
class _CustomerReadOnlyBanner extends StatelessWidget {
  const _CustomerReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.customerReadOnlyBannerTitle,
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.customerReadOnlyBannerMessage,
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/account/subscription'),
                  child: Text(l10n.customerReadOnlyBannerUpgradeButton),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
