import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../attachments/data/attachment_repository.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/presentation/providers/customer_actions.dart';
import '../../../debts/domain/debt.dart';
import '../../../debts/presentation/providers/debt_actions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/add_case_review_input.dart';

/// Add Case wizard's final step. Reviews everything collected, then on
/// confirm chains the real mutations as one business workflow:
/// (`POST /customers` if New Customer) -> `POST /customers/{id}/debts` ->
/// (`POST /debts/{id}/attachments` if an invoice was picked in the Debt
/// Details step) -> `POST /debts/{id}/collection-cases`.
///
/// No rollback is attempted on a mid-chain failure — confirmed with the
/// Product Owner that neither `archive()` endpoint reverses a created
/// record's financial impact (it's a pure soft-delete flag; the customer's
/// `outstanding_balance` recalculation explicitly still counts archived
/// debts). A failure after a real record was created surfaces the exact
/// error plus a direct link to that record instead of hiding it. The
/// invoice attach step follows the same philosophy but even more
/// leniently: it's best-effort and its failure is silent (the Debt and
/// Case still get created normally) since losing an optional attachment
/// shouldn't block the wizard's primary outcome.
class AddCaseReviewScreen extends ConsumerStatefulWidget {
  final AddCaseReviewInput input;

  const AddCaseReviewScreen({super.key, required this.input});

  @override
  ConsumerState<AddCaseReviewScreen> createState() =>
      _AddCaseReviewScreenState();
}

sealed class _ReviewState {
  const _ReviewState();
}

class _Idle extends _ReviewState {
  const _Idle();
}

class _Running extends _ReviewState {
  const _Running();
}

/// Nothing was created yet (Customer creation failed, or — Existing
/// Customer path — Debt creation failed with no prior step to have
/// created anything). Safe to just show the error and let the user retry.
class _FailedNothingCreated extends _ReviewState {
  final String message;
  const _FailedNothingCreated(this.message);
}

/// The Customer was created successfully but Debt creation failed.
class _FailedAfterCustomer extends _ReviewState {
  final String message;
  final Customer customer;
  const _FailedAfterCustomer(this.message, this.customer);
}

/// The Debt was created successfully (Customer too, if New Customer path)
/// but Collection Case creation failed.
class _FailedAfterDebt extends _ReviewState {
  final String message;
  final Debt debt;
  const _FailedAfterDebt(this.message, this.debt);
}

class _AddCaseReviewScreenState extends ConsumerState<AddCaseReviewScreen> {
  _ReviewState _state = const _Idle();

  bool get _isNewCustomer => widget.input.customerDraft != null;

  Future<void> _confirm() async {
    setState(() => _state = const _Running());

    final debtDraft = widget.input.debtDraft;
    Customer customer;

    if (_isNewCustomer) {
      final draft = widget.input.customerDraft!;
      try {
        final result = await ref
            .read(customerActionsProvider)
            .create(
              name: draft.name,
              phone: draft.phone,
              address: draft.address,
              creditLimit: draft.creditLimit,
              phoneNumbers: draft.phoneNumbers,
            );
        customer = result.customer;
      } on ApiException catch (e) {
        if (mounted) setState(() => _state = _FailedNothingCreated(e.message));
        return;
      }
    } else {
      customer = widget.input.existingCustomer!;
    }

    Debt debt;
    try {
      final result = await ref
          .read(debtActionsProvider)
          .create(
            customerId: customer.id,
            amount: debtDraft.amount,
            dueDate: debtDraft.dueDate,
            notes: debtDraft.notes,
          );
      debt = result.debt;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _state = _isNewCustomer
              ? _FailedAfterCustomer(e.message, customer)
              : _FailedNothingCreated(e.message);
        });
      }
      return;
    }

    final invoiceFile = debtDraft.invoiceFile;
    if (invoiceFile != null) {
      try {
        await ref
            .read(attachmentRepositoryProvider)
            .uploadAttachment(
              entityPathPrefix: 'debts/${debt.id}',
              filePath: invoiceFile.path,
              fileName: invoiceFile.name,
              description: 'Invoice',
            );
      } on ApiException {
        // Best-effort, same "no rollback on a later failure" convention as
        // the rest of this chain — the Debt itself was created
        // successfully, so a failed invoice attach doesn't block Case
        // creation below.
      }
    }

    try {
      final collectionCase = await ref
          .read(debtActionsProvider)
          .openCase(debt.id, customer.id);
      if (!mounted) return;
      // `go()`, not `push()`/`pushReplacement()` — clears the whole wizard
      // stack (entry sheet's pushed steps) now that the flow is complete,
      // rather than leaving stale draft-collection screens behind Case
      // Detail's back button.
      GoRouter.of(context).go('/cases/${collectionCase.id}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _state = _FailedAfterDebt(e.message, debt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final input = widget.input;
    final debtDraft = input.debtDraft;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addCaseReviewTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                l10n.addCaseReviewCustomerHeading,
                style: AppTypography.heading,
              ),
              const SizedBox(height: 12),
              if (input.existingCustomer case final customer?) ...[
                Text(customer.name, style: AppTypography.body),
                Text(customer.phone, style: AppTypography.caption),
              ] else if (input.customerDraft case final draft?) ...[
                Text(draft.name, style: AppTypography.body),
                Text(draft.phone, style: AppTypography.caption),
                Text(
                  l10n.addCaseReviewCreditLimitLabel(draft.creditLimit),
                  style: AppTypography.caption,
                ),
              ],
              const SizedBox(height: 24),
              Text(l10n.addCaseReviewDebtHeading, style: AppTypography.heading),
              const SizedBox(height: 12),
              Text(
                l10n.addCaseReviewAmountLabel(debtDraft.amount),
                style: AppTypography.body,
              ),
              Text(
                l10n.addCaseReviewDueDateLabel(debtDraft.dueDate),
                style: AppTypography.body,
              ),
              if (debtDraft.notes != null)
                Text(
                  l10n.addCaseReviewNotesLabel(debtDraft.notes!),
                  style: AppTypography.caption,
                ),
              if (debtDraft.invoiceFile != null)
                Text(
                  l10n.addCaseReviewInvoiceLabel(debtDraft.invoiceFile!.name),
                  style: AppTypography.caption,
                ),
              const SizedBox(height: 32),
              _buildStateSection(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateSection(BuildContext context, AppLocalizations l10n) {
    final label = _isNewCustomer
        ? l10n.addCaseReviewCreateCustomerDebtButton
        : l10n.addCaseReviewCreateDebtButton;
    final state = _state;
    return switch (state) {
      _Idle() => PrimaryButton(label: label, onPressed: _confirm),
      _Running() => PrimaryButton(
        label: label,
        isLoading: true,
        onPressed: null,
      ),
      _FailedNothingCreated(:final message) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: l10n.addCaseReviewTryAgainButton,
            onPressed: _confirm,
          ),
        ],
      ),
      _FailedAfterCustomer(:final message, :final customer) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addCaseReviewCustomerCreatedDebtFailedMessage(
              customer.name,
              message,
            ),
            style: AppTypography.body,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () =>
                GoRouter.of(context).push('/customers/${customer.id}'),
            child: Text(l10n.addCaseReviewOpenCustomerButton),
          ),
        ],
      ),
      _FailedAfterDebt(:final message, :final debt) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.addCaseReviewDebtCreatedCaseFailedMessage(
              debt.referenceNumber,
              message,
            ),
            style: AppTypography.body,
          ),
          const SizedBox(height: 8),
          Text(l10n.addCaseReviewCaseLaterHint, style: AppTypography.caption),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => GoRouter.of(context).push('/debts/${debt.id}'),
            child: Text(l10n.addCaseReviewOpenDebtButton),
          ),
        ],
      ),
    };
  }
}
